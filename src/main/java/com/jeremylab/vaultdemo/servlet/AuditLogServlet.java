package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.service.AuditLogService;
import jakarta.inject.Inject;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

/**
 * 稽核日誌 Servlet。
 * GET /audit → 顯示應用程式層操作記錄，支援依操作類型過濾。
 */
@WebServlet("/audit")
public class AuditLogServlet extends HttpServlet {

    @Inject
    private AuditLogService auditLog;

    /** 所有可過濾的操作類型 */
    private static final String[] OPERATIONS = {
        AuditEntry.OP_LOGIN,
        AuditEntry.OP_LOGOUT,
        AuditEntry.OP_GET_CREDS,
        AuditEntry.OP_RENEW_LEASE,
        AuditEntry.OP_REVOKE_LEASE,
        AuditEntry.OP_MONGO_QUERY,
        AuditEntry.OP_MONGO_INSERT,
        AuditEntry.OP_MONGO_DELETE,
        AuditEntry.OP_LOOKUP_TOKEN
    };

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String operationFilter = req.getParameter("operation");
        String limitStr        = req.getParameter("limit");

        int limit = 50;
        if (limitStr != null && !limitStr.isEmpty()) {
            try { limit = Integer.parseInt(limitStr); } catch (NumberFormatException ignored) {}
        }

        List<AuditEntry> entries = (operationFilter != null && !operationFilter.isEmpty())
                ? auditLog.getByOperation(operationFilter, limit)
                : auditLog.getRecent(limit);

        req.setAttribute("entries",          entries);
        req.setAttribute("total",            auditLog.getCount());
        req.setAttribute("operations",       OPERATIONS);
        req.setAttribute("operationFilter",  operationFilter);
        req.setAttribute("limit",            limit);

        req.getRequestDispatcher("/WEB-INF/views/audit-log.jsp").forward(req, resp);
    }
}
