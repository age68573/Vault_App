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
 * 儀表板 Servlet。
 * GET /dashboard → 顯示 Token 資訊、活躍 Lease 數量及 MongoDB 連線狀態。
 */
@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

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

        HttpSession    session  = req.getSession(false);
        VaultToken     token    = (VaultToken) session.getAttribute("vaultToken");
        String         username = (String) session.getAttribute("vaultUsername");
        DynamicCredential cred = (DynamicCredential) session.getAttribute("currentCred");

        // 向 Vault 取得最新的 Token 資訊（更新 TTL）
        try {
            VaultToken refreshed = vaultService.lookupSelf(token.getClientToken());
            // 保留原本的 clientToken（lookup-self 回應中 id 欄位有時為空）
            if (refreshed.getClientToken() == null || refreshed.getClientToken().isEmpty()) {
                refreshed.setClientToken(token.getClientToken());
            }
            session.setAttribute("vaultToken", refreshed);
            token = refreshed;

            auditLog.record(AuditEntry.success(
                    AuditEntry.OP_LOOKUP_TOKEN,
                    "/v1/auth/token/lookup-self",
                    username,
                    null
            ));
        } catch (VaultException e) {
            req.setAttribute("tokenError", "無法取得 Token 資訊：" + e.getMessage());
        }

        // 取得已知 Lease 清單
        List<String> knownLeaseIds = (List<String>) session.getAttribute("knownLeaseIds");
        if (knownLeaseIds == null) knownLeaseIds = new ArrayList<>();

        List<LeaseInfo> leases = vaultService.lookupLeases(token.getClientToken(), knownLeaseIds);

        // 測試 MongoDB 連線（若有憑證）
        MongoService.ConnectionStatus connStatus = null;
        if (cred != null && !cred.isExpired()) {
            connStatus = mongoService.testConnection(cred);
        }

        req.setAttribute("token",        token);
        req.setAttribute("username",     username);
        req.setAttribute("leases",       leases);
        req.setAttribute("connStatus",   connStatus);
        req.setAttribute("currentCred",  cred);
        req.setAttribute("leaseCount",   leases.size());

        req.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(req, resp);
    }
}
