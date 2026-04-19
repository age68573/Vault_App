<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Lease 管理 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="leases" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="page-header d-print-none">
  <div class="container-xl">
    <div class="row g-2 align-items-center">
      <div class="col">
        <h2 class="page-title">Lease 管理</h2>
        <div class="text-muted mt-1 small">管理 Vault 動態憑證的租約生命週期</div>
      </div>
      <div class="col-auto ms-auto">
        <a href="${pageContext.request.contextPath}/leases" class="btn btn-outline-secondary btn-sm">
          <i class="bi bi-arrow-clockwise me-1"></i>重新整理
        </a>
      </div>
    </div>
  </div>
</div>

<div class="page-body">
  <div class="container-xl">

    <c:if test="${not empty msg}">
      <div class="alert alert-success alert-dismissible mb-4">
        <i class="bi bi-check-circle-fill me-2"></i><c:out value="${msg}"/>
        <a class="btn-close" data-bs-dismiss="alert"></a>
      </div>
    </c:if>
    <c:if test="${not empty error}">
      <div class="alert alert-danger alert-dismissible mb-4">
        <i class="bi bi-exclamation-triangle-fill me-2"></i><c:out value="${error}"/>
        <a class="btn-close" data-bs-dismiss="alert"></a>
      </div>
    </c:if>

    <div class="card">
      <div class="card-header">
        <h3 class="card-title">
          活躍租約清單
          <span class="badge bg-primary-lt text-primary ms-2">${fn:length(leases)}</span>
        </h3>
        <div class="card-options">
          <span class="text-muted small">
            <i class="bi bi-info-circle me-1"></i>
            <span class="badge bg-success-lt text-success me-1">綠</span>&gt;300s
            <span class="badge bg-warning-lt text-warning ms-1 me-1">黃</span>61-300s
            <span class="badge bg-danger-lt text-danger ms-1 me-1">紅</span>&le;60s
          </span>
        </div>
      </div>

      <c:choose>
        <c:when test="${empty leases}">
          <div class="card-body">
            <div class="empty">
              <div class="empty-icon">
                <i class="bi bi-inbox" style="font-size:2.5rem; color:var(--tblr-secondary);"></i>
              </div>
              <p class="empty-title">目前沒有活躍的 Lease</p>
              <p class="empty-subtitle text-muted">申請動態憑證後，對應的 Lease 將顯示於此</p>
              <div class="empty-action">
                <a href="${pageContext.request.contextPath}/creds" class="btn btn-primary btn-sm">
                  <i class="bi bi-key me-1"></i>申請動態憑證
                </a>
              </div>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-vcenter table-hover card-table">
              <thead>
                <tr>
                  <th>Lease ID</th>
                  <th>發行時間</th>
                  <th>到期時間</th>
                  <th class="text-center" style="width:160px;">TTL</th>
                  <th class="text-center" style="width:60px;">可續期</th>
                  <th class="text-center" style="width:140px;">操作</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="lease" items="${leases}" varStatus="ls">
                  <tr>
                    <td class="font-monospace small text-muted"
                        title="${lease.leaseId}"
                        data-bs-toggle="tooltip" data-bs-placement="top">
                      <c:out value="${lease.shortLeaseId}"/>
                    </td>
                    <td class="small text-muted"><c:out value="${lease.issueTime}"/></td>
                    <td class="small">
                      <c:choose>
                        <c:when test="${lease.almostExpired}">
                          <span class="text-danger">
                            <i class="bi bi-exclamation-triangle me-1"></i>
                            <c:out value="${lease.expireTime}"/>
                          </span>
                        </c:when>
                        <c:otherwise>
                          <c:out value="${lease.expireTime}"/>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="text-center">
                      <c:choose>
                        <c:when test="${lease.ttl > 300}">
                          <span class="badge bg-success-lt text-success mb-1"
                                data-ttl="${lease.ttl}" data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>s
                          </span>
                        </c:when>
                        <c:when test="${lease.ttl > 60}">
                          <span class="badge bg-warning-lt text-warning mb-1"
                                data-ttl="${lease.ttl}" data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>s
                          </span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-danger-lt text-danger mb-1"
                                data-ttl="${lease.ttl}" data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>s
                          </span>
                        </c:otherwise>
                      </c:choose>
                      <div class="progress progress-sm">
                        <div id="leaseTtlBar_${ls.index}"
                             class="progress-bar
                               <c:choose>
                                 <c:when test='${lease.ttl > 300}'>bg-success</c:when>
                                 <c:when test='${lease.ttl > 60}'>bg-warning</c:when>
                                 <c:otherwise>bg-danger</c:otherwise>
                               </c:choose>"
                             role="progressbar" data-total="${lease.ttl}" style="width:100%">
                        </div>
                      </div>
                    </td>
                    <td class="text-center">
                      <c:choose>
                        <c:when test="${lease.renewable}">
                          <span class="status-dot status-green d-inline-block"></span>
                        </c:when>
                        <c:otherwise>
                          <span class="status-dot status-secondary d-inline-block"></span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="text-center">
                      <div class="d-flex gap-1 justify-content-center lease-actions">
                        <c:if test="${lease.renewable}">
                          <form method="post" action="${pageContext.request.contextPath}/leases"
                                class="d-inline">
                            <input type="hidden" name="action"  value="renew">
                            <input type="hidden" name="leaseId" value="${lease.leaseId}">
                            <button type="submit" class="btn btn-sm btn-outline-primary"
                                    title="續期（+3600 秒）">
                              <i class="bi bi-arrow-repeat me-1"></i>續期
                            </button>
                          </form>
                        </c:if>
                        <form method="post" action="${pageContext.request.contextPath}/leases"
                              class="d-inline"
                              onsubmit="return confirmRevoke('${lease.shortLeaseId}')">
                          <input type="hidden" name="action"  value="revoke">
                          <input type="hidden" name="leaseId" value="${lease.leaseId}">
                          <button type="submit" class="btn btn-sm btn-outline-danger"
                                  title="立即撤銷此 Lease">
                            <i class="bi bi-trash3 me-1"></i>撤銷
                          </button>
                        </form>
                      </div>
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
<script>
function confirmRevoke(leaseId) {
  return confirm('確定要撤銷 Lease：' + leaseId + '？\n撤銷後對應的 MongoDB 帳號將立即失效，此操作無法復原。');
}
document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => new bootstrap.Tooltip(el));
</script>
