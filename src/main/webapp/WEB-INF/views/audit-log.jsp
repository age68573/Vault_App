<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="稽核日誌 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="audit" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="page-header d-print-none">
  <div class="container-xl">
    <div class="row g-2 align-items-center">
      <div class="col">
        <h2 class="page-title">稽核日誌</h2>
        <div class="text-muted mt-1 small">
          應用程式層操作記錄，共 <strong><c:out value="${total}"/></strong> 筆（最多保留 500 筆）
        </div>
      </div>
    </div>
  </div>
</div>

<div class="page-body">
  <div class="container-xl">

    <div class="alert alert-info mb-4">
      <div class="d-flex">
        <div><i class="bi bi-info-circle-fill me-2"></i></div>
        <div class="small">
          此為<strong>應用程式層</strong>操作記錄，非 Vault 官方 Audit Device 的替代品。
          如需完整的 Vault 稽核日誌，請在 Vault 伺服器啟用 <code>file</code> 或 <code>syslog</code> audit device。
        </div>
      </div>
    </div>

    <%-- 過濾列 --%>
    <div class="card mb-4">
      <div class="card-body">
        <form method="get" action="${pageContext.request.contextPath}/audit"
              class="row g-2 align-items-end">
          <div class="col-md-5">
            <label class="form-label small">操作類型</label>
            <select class="form-select form-select-sm" name="operation">
              <option value="">— 全部操作 —</option>
              <c:forEach var="op" items="${operations}">
                <option value="${op}" <c:if test="${op == operationFilter}">selected</c:if>>
                  <c:out value="${op}"/>
                </option>
              </c:forEach>
            </select>
          </div>
          <div class="col-md-2">
            <label class="form-label small">顯示筆數</label>
            <input type="number" class="form-control form-control-sm"
                   name="limit" value="${limit}" min="1" max="500">
          </div>
          <div class="col-md-2">
            <button type="submit" class="btn btn-secondary btn-sm w-100">
              <i class="bi bi-funnel me-1"></i>篩選
            </button>
          </div>
        </form>
      </div>
    </div>

    <%-- 日誌表格 --%>
    <div class="card">
      <c:choose>
        <c:when test="${empty entries}">
          <div class="card-body">
            <div class="empty">
              <div class="empty-icon">
                <i class="bi bi-journal-x" style="font-size:2.5rem; color:var(--tblr-secondary);"></i>
              </div>
              <p class="empty-title">尚無稽核記錄</p>
              <p class="empty-subtitle text-muted">操作 Vault 或 MongoDB 後記錄將顯示於此</p>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-vcenter table-hover card-table">
              <thead>
                <tr>
                  <th style="width:150px">時間</th>
                  <th style="width:130px">操作</th>
                  <th>Vault 路徑</th>
                  <th style="width:90px">使用者</th>
                  <th>Lease ID</th>
                  <th class="text-center" style="width:70px">結果</th>
                  <th>錯誤訊息</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="entry" items="${entries}">
                  <tr>
                    <td class="small text-muted font-monospace">
                      <c:out value="${entry.formattedTimestamp}"/>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${entry.operation == '登入 Vault'}">
                          <span class="badge bg-primary-lt text-primary"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '登出 Vault'}">
                          <span class="badge bg-secondary-lt text-secondary"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '申請動態憑證'}">
                          <span class="badge bg-warning-lt text-warning"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '撤銷 Lease'}">
                          <span class="badge bg-danger-lt text-danger"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '續期 Lease'}">
                          <span class="badge bg-info-lt text-info"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${fn:startsWith(entry.operation, 'MongoDB')}">
                          <span class="badge bg-success-lt text-success"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-secondary-lt text-secondary"><c:out value="${entry.operation}"/></span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="small font-monospace text-muted text-truncate"
                        style="max-width:180px;" title="${entry.vaultPath}">
                      <c:out value="${entry.vaultPath}"/>
                    </td>
                    <td class="small"><c:out value="${entry.vaultUsername}"/></td>
                    <td class="small font-monospace text-muted text-truncate"
                        style="max-width:140px;" title="${entry.leaseId}">
                      <c:out value="${entry.leaseId}"/>
                    </td>
                    <td class="text-center">
                      <c:choose>
                        <c:when test="${entry.success}">
                          <span class="badge bg-success-lt text-success">成功</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-danger-lt text-danger">失敗</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="small text-danger">
                      <c:out value="${entry.errorMessage}"/>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</div><%-- /page-body --%>

<%@ include file="_footer.jsp" %>
