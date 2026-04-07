<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Lease 管理 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="leases" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="container-fluid py-4">
  <div class="d-flex align-items-center mb-4">
    <h4 class="fw-bold mb-0">
      <i class="bi bi-hourglass-split me-2 text-primary"></i>Lease 管理
    </h4>
    <a href="${pageContext.request.contextPath}/leases"
       class="btn btn-sm btn-outline-secondary ms-3">
      <i class="bi bi-arrow-clockwise me-1"></i>重新整理
    </a>
  </div>

  <%-- 操作結果提示 --%>
  <c:if test="${not empty msg}">
    <div class="alert alert-success alert-dismissible fade show">
      <i class="bi bi-check-circle-fill me-1"></i><c:out value="${msg}"/>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="alert alert-danger alert-dismissible fade show">
      <i class="bi bi-exclamation-triangle-fill me-1"></i><c:out value="${error}"/>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>

  <div class="card shadow-sm border-0">
    <div class="card-header bg-dark text-white fw-semibold d-flex align-items-center">
      <i class="bi bi-list-ul me-2"></i>活躍租約清單
      <span class="badge bg-primary ms-2">${fn:length(leases)}</span>
    </div>
    <div class="card-body p-0">

      <c:choose>
        <c:when test="${empty leases}">
          <div class="text-center py-5 text-muted">
            <i class="bi bi-inbox" style="font-size:2.5rem;"></i>
            <p class="mt-2">目前沒有活躍的 Lease</p>
            <a href="${pageContext.request.contextPath}/creds"
               class="btn btn-sm btn-warning">
              <i class="bi bi-key me-1"></i>申請動態憑證以建立 Lease
            </a>
          </div>
        </c:when>
        <c:otherwise>
          <div class="table-responsive">
            <table class="table table-hover table-striped align-middle mb-0">
              <thead class="table-secondary">
                <tr>
                  <th>Lease ID</th>
                  <th>發行時間</th>
                  <th>到期時間</th>
                  <th class="text-center">TTL（秒）</th>
                  <th class="text-center">可續期</th>
                  <th class="text-center">操作</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="lease" items="${leases}" varStatus="ls">
                  <tr>
                    <td class="font-monospace small"
                        title="${lease.leaseId}"
                        data-bs-toggle="tooltip" data-bs-placement="top">
                      <c:out value="${lease.shortLeaseId}"/>
                    </td>
                    <td class="small text-muted"><c:out value="${lease.issueTime}"/></td>
                    <td class="small">
                      <c:choose>
                        <c:when test="${lease.almostExpired}">
                          <span class="text-danger fw-semibold">
                            <i class="bi bi-exclamation-triangle me-1"></i>
                            <c:out value="${lease.expireTime}"/>
                          </span>
                        </c:when>
                        <c:otherwise>
                          <c:out value="${lease.expireTime}"/>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="text-center" style="min-width:120px;">
                      <c:choose>
                        <c:when test="${lease.ttl > 300}">
                          <span class="badge bg-success mb-1"
                                data-ttl="${lease.ttl}"
                                data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>秒
                          </span>
                        </c:when>
                        <c:when test="${lease.ttl > 60}">
                          <span class="badge bg-warning text-dark mb-1"
                                data-ttl="${lease.ttl}"
                                data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>秒
                          </span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-danger mb-1"
                                data-ttl="${lease.ttl}"
                                data-bar="leaseTtlBar_${ls.index}">
                            <c:out value="${lease.ttl}"/>秒
                          </span>
                        </c:otherwise>
                      </c:choose>
                      <div class="progress" style="height:6px;">
                        <div id="leaseTtlBar_${ls.index}"
                             class="progress-bar ${lease.ttl > 300 ? 'bg-success' : (lease.ttl > 60 ? 'bg-warning' : 'bg-danger')}"
                             role="progressbar"
                             data-total="${lease.ttl}"
                             style="width:100%">
                        </div>
                      </div>
                    </td>
                    <td class="text-center">
                      <c:choose>
                        <c:when test="${lease.renewable}">
                          <i class="bi bi-check-circle-fill text-success"></i>
                        </c:when>
                        <c:otherwise>
                          <i class="bi bi-x-circle-fill text-secondary"></i>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="text-center">
                      <div class="btn-group btn-group-sm">

                        <%-- 續期按鈕 --%>
                        <c:if test="${lease.renewable}">
                          <form method="post"
                                action="${pageContext.request.contextPath}/leases"
                                class="d-inline">
                            <input type="hidden" name="action"  value="renew">
                            <input type="hidden" name="leaseId" value="${lease.leaseId}">
                            <button type="submit" class="btn btn-sm btn-outline-primary"
                                    title="續期此 Lease（增加 3600 秒）">
                              <i class="bi bi-arrow-repeat"></i>續期
                            </button>
                          </form>
                        </c:if>

                        <%-- 撤銷按鈕 --%>
                        <form method="post"
                              action="${pageContext.request.contextPath}/leases"
                              class="d-inline"
                              onsubmit="return confirmRevoke('${lease.shortLeaseId}')">
                          <input type="hidden" name="action"  value="revoke">
                          <input type="hidden" name="leaseId" value="${lease.leaseId}">
                          <button type="submit" class="btn btn-sm btn-outline-danger"
                                  title="立即撤銷此 Lease（憑證將無法使用）">
                            <i class="bi bi-trash3"></i>撤銷
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

  <div class="alert alert-secondary mt-3 small">
    <i class="bi bi-info-circle me-1"></i>
    <strong>TTL 顏色說明：</strong>
    <span class="badge bg-success me-1">綠色</span> &gt; 300 秒 &nbsp;
    <span class="badge bg-warning text-dark me-1">黃色</span> 61–300 秒 &nbsp;
    <span class="badge bg-danger me-1">紅色</span> &le; 60 秒（即將到期）
  </div>
</div>

<%@ include file="_footer.jsp" %>
<script>
function confirmRevoke(leaseId) {
  return confirm('確定要撤銷 Lease：' + leaseId + ' ？\n撤銷後對應的 MongoDB 帳號將立即失效，此操作無法復原。');
}

// 啟用 Bootstrap Tooltip
document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
  new bootstrap.Tooltip(el);
});
</script>
