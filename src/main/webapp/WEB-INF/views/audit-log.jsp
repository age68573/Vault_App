<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="稽核日誌 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="audit" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="container-xl py-4">

  <div class="page-header d-print-none mb-4">
    <div class="row align-items-center">
      <div class="col">
        <h2 class="page-title">
          <i class="bi bi-journal-text me-2 text-secondary"></i>應用程式稽核日誌
        </h2>
      </div>
    </div>
  </div>

  <div class="alert alert-info small mb-4">
    <i class="bi bi-info-circle-fill me-1"></i>
    此為<strong>應用程式層</strong>操作記錄（最多保留 500 筆），非 Vault 官方 Audit Device 的替代品。
    如需完整的 Vault 稽核日誌，請在 Vault 伺服器上啟用
    <code>file</code> 或 <code>syslog</code> audit device。
    <br>目前共 <strong><c:out value="${total}"/></strong> 筆記錄。
  </div>

  <%-- 過濾列 --%>
  <div class="card mb-4">
    <div class="card-body py-2">
      <form method="get" action="${pageContext.request.contextPath}/audit"
            class="row g-2 align-items-end">
        <div class="col-md-5">
          <label class="form-label small fw-semibold mb-1">操作類型</label>
          <select class="form-select form-select-sm" name="operation">
            <option value="">— 全部操作 —</option>
            <c:forEach var="op" items="${operations}">
              <option value="${op}"
                <c:if test="${op == operationFilter}">selected</c:if>>
                <c:out value="${op}"/>
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="col-md-2">
          <label class="form-label small fw-semibold mb-1">顯示筆數</label>
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
    <div class="card-body p-0">
      <c:choose>
        <c:when test="${empty entries}">
          <div class="empty py-5">
            <div class="empty-icon">
              <i class="bi bi-journal-x" style="font-size:2.5rem; color:#adb5bd;"></i>
            </div>
            <p class="empty-title mt-2">尚無稽核記錄</p>
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-sm table-hover table-vcenter align-middle mb-0">
              <thead>
                <tr>
                  <th style="width:150px">時間</th>
                  <th style="width:140px">操作</th>
                  <th>Vault 路徑</th>
                  <th style="width:100px">使用者</th>
                  <th>Lease ID</th>
                  <th class="text-center" style="width:80px">結果</th>
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
                          <span class="badge bg-primary"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '登出 Vault'}">
                          <span class="badge bg-secondary"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '申請動態憑證'}">
                          <span class="badge bg-warning text-dark">
                            <c:out value="${entry.operation}"/>
                          </span>
                        </c:when>
                        <c:when test="${entry.operation == '撤銷 Lease'}">
                          <span class="badge bg-danger"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:when test="${entry.operation == '續期 Lease'}">
                          <span class="badge bg-info text-dark">
                            <c:out value="${entry.operation}"/>
                          </span>
                        </c:when>
                        <c:when test="${fn:startsWith(entry.operation, 'MongoDB')}">
                          <span class="badge bg-success"><c:out value="${entry.operation}"/></span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-light text-dark border">
                            <c:out value="${entry.operation}"/>
                          </span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="small font-monospace text-muted text-truncate"
                        style="max-width:200px;" title="${entry.vaultPath}">
                      <c:out value="${entry.vaultPath}"/>
                    </td>
                    <td class="small"><c:out value="${entry.vaultUsername}"/></td>
                    <td class="small font-monospace text-muted text-truncate"
                        style="max-width:150px;" title="${entry.leaseId}">
                      <c:out value="${entry.leaseId}"/>
                    </td>
                    <td class="text-center">
                      <c:choose>
                        <c:when test="${entry.success}">
                          <span class="badge bg-success">成功</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-danger">失敗</span>
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

</div>

<%@ include file="_footer.jsp" %>
