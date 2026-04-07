package com.jeremylab.vaultdemo.servlet;

import com.jeremylab.vaultdemo.model.AuditEntry;
import com.jeremylab.vaultdemo.model.DynamicCredential;
import com.jeremylab.vaultdemo.service.AuditLogService;
import com.jeremylab.vaultdemo.service.MongoService;
import com.mongodb.MongoException;
import jakarta.inject.Inject;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

/**
 * MongoDB 資料瀏覽器 Servlet。
 * GET  /data → 列出 Collection 清單，若指定 collection 參數則查詢文件
 * POST /data → 執行 CRUD 操作（action=insert 或 action=delete）
 */
@WebServlet("/data")
public class DataExplorerServlet extends HttpServlet {

    @Inject
    private MongoService mongoService;

    @Inject
    private AuditLogService auditLog;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession       session = req.getSession(false);
        DynamicCredential cred    = (DynamicCredential) session.getAttribute("currentCred");
        String            username = (String) session.getAttribute("vaultUsername");

        if (cred == null || cred.isExpired()) {
            req.setAttribute("noCred", true);
            req.getRequestDispatcher("/WEB-INF/views/data-explorer.jsp").forward(req, resp);
            return;
        }

        try {
            // 列出所有 Collection
            List<String> collections = mongoService.listCollections(cred);
            req.setAttribute("collections", collections);

            // 若有指定 Collection，查詢文件
            String collectionName = req.getParameter("collection");
            if (collectionName != null && !collectionName.trim().isEmpty()) {
                String filterJson = req.getParameter("filter");
                String limitStr   = req.getParameter("limit");
                int limit = 20;
                if (limitStr != null && !limitStr.isEmpty()) {
                    try { limit = Integer.parseInt(limitStr); } catch (NumberFormatException ignored) {}
                }

                List<String> documents =
                        mongoService.findDocuments(cred, collectionName, filterJson, limit);

                auditLog.record(AuditEntry.success(
                        AuditEntry.OP_MONGO_QUERY,
                        "mongodb://" + collectionName,
                        username,
                        cred.getLeaseId()
                ));

                req.setAttribute("selectedCollection", collectionName);
                req.setAttribute("documents",          documents);
                req.setAttribute("documentCount",      documents.size());
                req.setAttribute("filterJson",         filterJson);
                req.setAttribute("limit",              limit);
            }

        } catch (MongoException e) {
            req.setAttribute("dbError", "資料庫操作失敗：" + e.getMessage());
        }

        req.setAttribute("currentCred", cred);
        req.setAttribute("username",    username);
        req.getRequestDispatcher("/WEB-INF/views/data-explorer.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        HttpSession       session  = req.getSession(false);
        DynamicCredential cred     = (DynamicCredential) session.getAttribute("currentCred");
        String            username = (String) session.getAttribute("vaultUsername");

        if (cred == null || cred.isExpired()) {
            resp.sendRedirect(req.getContextPath() + "/data");
            return;
        }

        String action         = req.getParameter("action");
        String collectionName = req.getParameter("collection");

        try {
            if ("insert".equals(action)) {
                String documentJson = req.getParameter("documentJson");
                if (documentJson == null || documentJson.trim().isEmpty()) {
                    resp.sendRedirect(req.getContextPath() + "/data?collection=" + collectionName
                            + "&error=文件內容不得為空");
                    return;
                }
                String insertedId = mongoService.insertDocument(cred, collectionName, documentJson);

                auditLog.record(AuditEntry.success(
                        AuditEntry.OP_MONGO_INSERT,
                        "mongodb://" + collectionName,
                        username,
                        cred.getLeaseId()
                ));
                resp.sendRedirect(req.getContextPath() + "/data?collection=" + collectionName
                        + "&msg=文件已新增，_id=" + insertedId);

            } else if ("delete".equals(action)) {
                String filterJson = req.getParameter("filterJson");
                if (filterJson == null || filterJson.trim().isEmpty()) {
                    resp.sendRedirect(req.getContextPath() + "/data?collection=" + collectionName
                            + "&error=篩選條件不得為空");
                    return;
                }
                long deleted = mongoService.deleteDocuments(cred, collectionName, filterJson);

                auditLog.record(AuditEntry.success(
                        AuditEntry.OP_MONGO_DELETE,
                        "mongodb://" + collectionName,
                        username,
                        cred.getLeaseId()
                ));
                resp.sendRedirect(req.getContextPath() + "/data?collection=" + collectionName
                        + "&msg=已刪除+" + deleted + "+筆文件");

            } else {
                resp.sendRedirect(req.getContextPath() + "/data");
            }

        } catch (MongoException e) {
            String op = "insert".equals(action) ? AuditEntry.OP_MONGO_INSERT
                                                 : AuditEntry.OP_MONGO_DELETE;
            auditLog.record(AuditEntry.failure(op, "mongodb://" + collectionName,
                    username, e.getMessage()));
            resp.sendRedirect(req.getContextPath() + "/data?collection=" + collectionName
                    + "&error=操作失敗：" + e.getMessage());
        }
    }
}
