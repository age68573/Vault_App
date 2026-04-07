package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.model.DynamicCredential;
import com.jeremylab.vaultdemo.model.LeaseInfo;
import com.jeremylab.vaultdemo.model.VaultToken;
import com.jeremylab.vaultdemo.service.AuditLogService;
import com.jeremylab.vaultdemo.service.MongoService;
import com.jeremylab.vaultdemo.service.VaultException;
import com.jeremylab.vaultdemo.service.VaultService;
import jakarta.inject.Inject;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * Lease 管理 Servlet。
 * GET  /leases        → 列出所有活躍的 Lease
 * POST /leases        → 執行 Lease 操作（action=renew 或 action=revoke）
 */
@WebServlet("/leases")
public class LeaseManagerServlet extends HttpServlet {

    @Inject
    private VaultService vaultService;

    @Inject
    private MongoService mongoService;

    @Inject
    private AuditLogService auditLog;

    @Override
    @SuppressWarnings("unchecked")
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session  = req.getSession(false);
        VaultToken  token    = (VaultToken) session.getAttribute("vaultToken");
        String      username = (String) session.getAttribute("vaultUsername");

        // 取得活躍 Lease 清單（優先向 Vault LIST，失敗時退回 Session 清單）
        List<String> knownLeaseIds = (List<String>) session.getAttribute("knownLeaseIds");
        if (knownLeaseIds == null) knownLeaseIds = new ArrayList<>();

        List<LeaseInfo> leases =
                vaultService.listAndLookupLeases(token.getClientToken(), knownLeaseIds);

        req.setAttribute("leases",   leases);
        req.setAttribute("username", username);
        req.setAttribute("msg",      req.getParameter("msg"));
        req.setAttribute("error",    req.getParameter("error"));

        req.getRequestDispatcher("/WEB-INF/views/lease-manager.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        HttpSession session  = req.getSession(false);
        VaultToken  token    = (VaultToken) session.getAttribute("vaultToken");
        String      username = (String) session.getAttribute("vaultUsername");

        String action  = req.getParameter("action");
        String leaseId = req.getParameter("leaseId");

        if (leaseId == null || leaseId.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/leases?error=缺少+Lease+ID");
            return;
        }

        try {
            if ("renew".equals(action)) {
                // 續期：預設增加 3600 秒
                LeaseInfo updated =
                        vaultService.renewLease(token.getClientToken(), leaseId, 3600);

                auditLog.record(AuditEntry.success(
                        AuditEntry.OP_RENEW_LEASE,
                        "/v1/sys/leases/renew",
                        username,
                        leaseId
                ));
                resp.sendRedirect(req.getContextPath() +
                        "/leases?msg=Lease+已續期，新+TTL+" + updated.getTtl() + "+秒");

            } else if ("revoke".equals(action)) {
                // 撤銷：移除 MongoClient 並撤銷 Lease
                mongoService.closeClient(leaseId);
                vaultService.revokeLease(token.getClientToken(), leaseId);

                // 若撤銷的是 Session 中目前使用的憑證，清除之
                DynamicCredential currentCred =
                        (DynamicCredential) session.getAttribute("currentCred");
                if (currentCred != null && leaseId.equals(currentCred.getLeaseId())) {
                    session.removeAttribute("currentCred");
                }

                // 從已知 Lease ID 清單中移除
                List<String> knownLeaseIds =
                        (List<String>) session.getAttribute("knownLeaseIds");
                if (knownLeaseIds != null) {
                    knownLeaseIds.remove(leaseId);
                }

                auditLog.record(AuditEntry.success(
                        AuditEntry.OP_REVOKE_LEASE,
                        "/v1/sys/leases/revoke",
                        username,
                        leaseId
                ));
                resp.sendRedirect(req.getContextPath() + "/leases?msg=Lease+已成功撤銷");

            } else {
                resp.sendRedirect(req.getContextPath() + "/leases?error=未知操作");
            }

        } catch (VaultException e) {
            String op = "revoke".equals(action) ? AuditEntry.OP_REVOKE_LEASE
                                                 : AuditEntry.OP_RENEW_LEASE;
            auditLog.record(AuditEntry.failure(op,
                    "/v1/sys/leases/" + action, username, e.getMessage()));
            resp.sendRedirect(req.getContextPath() +
                    "/leases?error=操作失敗：" + e.getMessage());
        }
    }
}
