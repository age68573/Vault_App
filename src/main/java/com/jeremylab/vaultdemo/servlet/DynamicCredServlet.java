package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.config.AppConfig;
import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.model.DynamicCredential;
import com.jeremylab.vaultdemo.model.VaultToken;
import com.jeremylab.vaultdemo.service.AuditLogService;
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
 * 動態憑證 Servlet。
 * GET  /creds → 顯示目前的動態憑證資訊及申請表單
 * POST /creds → 向 Vault 申請新的 MongoDB 動態憑證
 */
@WebServlet("/creds")
public class DynamicCredServlet extends HttpServlet {

    @Inject
    private VaultService vaultService;

    @Inject
    private AuditLogService auditLog;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession       session = req.getSession(false);
        DynamicCredential cred    = (DynamicCredential) session.getAttribute("currentCred");
        String            username = (String) session.getAttribute("vaultUsername");

        req.setAttribute("currentCred", cred);
        req.setAttribute("username",    username);
        req.setAttribute("vaultRole",   AppConfig.VAULT_DB_ROLE);
        req.setAttribute("successMsg",  req.getParameter("success"));

        req.getRequestDispatcher("/WEB-INF/views/dynamic-creds.jsp").forward(req, resp);
    }

    @Override
    @SuppressWarnings("unchecked")
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session  = req.getSession(false);
        VaultToken  token    = (VaultToken) session.getAttribute("vaultToken");
        String      username = (String) session.getAttribute("vaultUsername");

        try {
            DynamicCredential newCred =
                    vaultService.getDatabaseCredential(token.getClientToken());

            // 儲存新憑證至 Session
            session.setAttribute("currentCred", newCred);

            // 將新的 Lease ID 加入已知清單
            List<String> knownLeaseIds = (List<String>) session.getAttribute("knownLeaseIds");
            if (knownLeaseIds == null) {
                knownLeaseIds = new ArrayList<>();
            }
            knownLeaseIds.add(newCred.getLeaseId());
            session.setAttribute("knownLeaseIds", knownLeaseIds);

            auditLog.record(AuditEntry.success(
                    AuditEntry.OP_GET_CREDS,
                    "/v1/database/creds/" + AppConfig.VAULT_DB_ROLE,
                    username,
                    newCred.getLeaseId()
            ));

            // PRG 模式：重導至 GET，避免重複提交
            resp.sendRedirect(req.getContextPath() + "/creds?success=1");

        } catch (VaultException e) {
            auditLog.record(AuditEntry.failure(
                    AuditEntry.OP_GET_CREDS,
                    "/v1/database/creds/" + AppConfig.VAULT_DB_ROLE,
                    username,
                    e.getMessage()
            ));

            req.setAttribute("error",      "申請動態憑證失敗：" + e.getMessage());
            req.setAttribute("currentCred", session.getAttribute("currentCred"));
            req.setAttribute("vaultRole",   AppConfig.VAULT_DB_ROLE);
            req.getRequestDispatcher("/WEB-INF/views/dynamic-creds.jsp").forward(req, resp);
        }
    }
}
