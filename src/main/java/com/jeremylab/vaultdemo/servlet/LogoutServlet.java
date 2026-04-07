package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.model.VaultToken;
import com.jeremylab.vaultdemo.service.AuditLogService;
import com.jeremylab.vaultdemo.service.VaultService;
import jakarta.inject.Inject;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * 登出 Servlet。
 * POST /logout → 撤銷 Vault Token，清除 Session，重導至登入頁面。
 */
@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    @Inject
    private VaultService vaultService;

    @Inject
    private AuditLogService auditLog;

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session  = req.getSession(false);
        if (session != null) {
            VaultToken token    = (VaultToken) session.getAttribute("vaultToken");
            String     username = (String) session.getAttribute("vaultUsername");

            if (token != null) {
                // 盡力撤銷 Token（失敗時僅記錄日誌，不阻斷登出流程）
                vaultService.revokeSelf(token.getClientToken());
            }

            auditLog.record(AuditEntry.success(
                    AuditEntry.OP_LOGOUT,
                    "/v1/auth/token/revoke-self",
                    username != null ? username : "未知使用者",
                    null
            ));

            session.invalidate();
        }

        resp.sendRedirect(req.getContextPath() + "/login");
    }
}
