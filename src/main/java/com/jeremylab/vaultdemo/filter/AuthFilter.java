package com.jeremylab.vaultdemo.filter;

import com.jeremylab.vaultdemo.model.VaultToken;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

/**
 * 身份驗證過濾器。
 * 保護所有受限頁面，確保使用者持有有效的 Vault Token 才能存取。
 * 若 Token 不存在或已過期，重導至登入頁面。
 */
@WebFilter(urlPatterns = {
        "/dashboard",
        "/creds",
        "/leases",
        "/data",
        "/audit"
})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req     = (HttpServletRequest) request;
        HttpServletResponse res     = (HttpServletResponse) response;
        HttpSession         session = req.getSession(false);

        VaultToken token = (session != null)
                ? (VaultToken) session.getAttribute("vaultToken")
                : null;

        // Token 不存在或已過期，強制重新登入
        if (token == null || token.isExpired()) {
            if (session != null) {
                session.invalidate();
            }
            res.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        chain.doFilter(request, response);
    }
}
