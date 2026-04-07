package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.model.VaultToken;
import com.jeremylab.vaultdemo.service.AuditLogService;
import com.jeremylab.vaultdemo.service.VaultAuthException;
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

/**
 * 登入 Servlet。
 * GET  /login → 顯示登入頁面
 * POST /login → 驗證 Vault 帳號密碼，成功後重導至儀表板
 */
@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    @Inject
    private VaultService vaultService;

    @Inject
    private AuditLogService auditLog;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // 若已有有效 Token，直接跳轉儀表板
        HttpSession session = req.getSession(false);
        if (session != null) {
            VaultToken token = (VaultToken) session.getAttribute("vaultToken");
            if (token != null && !token.isExpired()) {
                resp.sendRedirect(req.getContextPath() + "/dashboard");
                return;
            }
        }
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "使用者名稱與密碼不得為空白");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        try {
            VaultToken token = vaultService.login(username.trim(), password);

            // 建立新 Session，防止 Session Fixation 攻擊
            HttpSession oldSession = req.getSession(false);
            if (oldSession != null) oldSession.invalidate();
            HttpSession newSession = req.getSession(true);
            newSession.setAttribute("vaultToken", token);
            newSession.setAttribute("vaultUsername", username.trim());

            auditLog.record(AuditEntry.success(
                    AuditEntry.OP_LOGIN,
                    "/v1/auth/userpass/login/" + username,
                    username.trim(),
                    null
            ));

            resp.sendRedirect(req.getContextPath() + "/dashboard");

        } catch (VaultAuthException e) {
            auditLog.record(AuditEntry.failure(
                    AuditEntry.OP_LOGIN,
                    "/v1/auth/userpass/login/" + username,
                    username.trim(),
                    e.getMessage()
            ));
            req.setAttribute("error", "帳號或密碼錯誤，請確認後重試");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);

        } catch (VaultException e) {
            auditLog.record(AuditEntry.failure(
                    AuditEntry.OP_LOGIN,
                    "/v1/auth/userpass/login/" + username,
                    username.trim(),
                    e.getMessage()
            ));
            req.setAttribute("error", "連線 Vault 失敗：" + e.getMessage());
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
        }
    }
}
