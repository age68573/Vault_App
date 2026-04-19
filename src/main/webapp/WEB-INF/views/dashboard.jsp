<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="儀表板 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="dashboard" scope="request"/>
<%@ include file="_header.jsp" %>

<%-- Page Header --%>
<div class="page-header d-print-none">
  <div class="container-xl">
    <div class="row g-2 align-items-center">
      <div class="col">
        <h2 class="page-title">儀表板</h2>
        <div class="text-muted mt-1 small">Vault Token 與 MongoDB 動態憑證狀態總覽</div>
      </div>
      <div class="col-auto ms-auto">
        <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-outline-secondary btn-sm">
          <i class="bi bi-arrow-clockwise me-1"></i>重新整理
        </a>
      </div>
    </div>
  </div>
</div>

<%-- Page Body --%>
<div class="page-body">
  <div class="container-xl">

    <c:if test="${not empty tokenError}">
      <div class="alert alert-warning mb-4">
        <i class="bi bi-exclamation-triangle me-2"></i><c:out value="${tokenError}"/>
      </div>
    </c:if>

    <%-- 統計卡片列 --%>
    <div class="row row-deck row-cards mb-4">

      <%-- Vault Token --%>
      <div class="col-md-4">
        <div class="card">
          <div class="card-header">
            <h3 class="card-title">
              <span class="avatar avatar-sm bg-primary-lt text-primary me-2">
                <i class="bi bi-shield-check"></i>
              </span>
              Vault Token
            </h3>
          </div>
          <div class="card-body">
            <c:choose>
              <c:when test="${not empty token}">
                <dl class="row mb-0">
                  <dt class="col-5 text-muted small fw-normal">存取器</dt>
                  <dd class="col-7 small font-monospace text-truncate mb-1" title="${token.accessor}">
                    <c:out value="${token.accessor}"/>
                  </dd>

                  <dt class="col-5 text-muted small fw-normal">政策</dt>
                  <dd class="col-7 mb-1">
                    <c:forEach var="p" items="${token.policies}">
                      <span class="badge bg-primary-lt text-primary me-1">
                        <c:out value="${p}"/>
                      </span>
                    </c:forEach>
                  </dd>

                  <dt class="col-5 text-muted small fw-normal">可續期</dt>
                  <dd class="col-7 mb-2">
                    <c:choose>
                      <c:when test="${token.renewable}">
                        <span class="badge bg-success-lt text-success">是</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge bg-secondary-lt text-secondary">否</span>
                      </c:otherwise>
                    </c:choose>
                  </dd>

                  <dt class="col-5 text-muted small fw-normal pt-1">剩餘 TTL</dt>
                  <dd class="col-7 mb-0">
                    <c:set var="ttl"      value="${token.remainingTtlSeconds}"/>
                    <c:set var="totalTtl" value="${token.ttl}"/>
                    <span class="badge mb-1
                      <c:choose>
                        <c:when test='${ttl > 300}'>bg-success</c:when>
                        <c:when test='${ttl > 60}'>bg-warning text-dark</c:when>
                        <c:otherwise>bg-danger</c:otherwise>
                      </c:choose>"
                      id="dashTtl" data-ttl="${ttl}" data-bar="dashTtlBar">
                      <c:out value="${ttl}"/>秒
                    </span>
                    <div class="progress progress-sm progress-track-success mt-1">
                      <div id="dashTtlBar" class="progress-bar
                        <c:choose>
                          <c:when test='${ttl > 300}'>bg-success</c:when>
                          <c:when test='${ttl > 60}'>bg-warning</c:when>
                          <c:otherwise>bg-danger</c:otherwise>
                        </c:choose>"
                        role="progressbar" data-total="${totalTtl}"
                        style="width:${ttl * 100 / (totalTtl > 0 ? totalTtl : 1)}%">
                      </div>
                    </div>
                  </dd>
                </dl>
              </c:when>
              <c:otherwise>
                <div class="empty empty-sm">
                  <p class="empty-subtitle text-muted">無法取得 Token 資訊</p>
                </div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>

      <%-- 活躍 Lease --%>
      <div class="col-md-4">
        <div class="card">
          <div class="card-header">
            <h3 class="card-title">
              <span class="avatar avatar-sm bg-warning-lt text-warning me-2">
                <i class="bi bi-hourglass-split"></i>
              </span>
              活躍 Lease
            </h3>
            <div class="card-options">
              <a href="${pageContext.request.contextPath}/leases"
                 class="btn btn-sm btn-ghost-secondary">
                管理
              </a>
            </div>
          </div>
          <div class="card-body">
            <div class="d-flex align-items-baseline mb-3">
              <div class="h1 mb-0 me-2">
                <c:out value="${leaseCount}"/>
              </div>
              <div class="text-muted small">筆活躍租約</div>
            </div>
            <c:if test="${not empty leases}">
              <div class="list-group list-group-flush list-group-hoverable">
                <c:forEach var="lease" items="${leases}" end="2">
                  <div class="list-group-item px-0 py-2">
                    <div class="row align-items-center">
                      <div class="col-auto">
                        <span class="status-dot status-green d-block"></span>
                      </div>
                      <div class="col text-truncate">
                        <span class="font-monospace small text-muted">
                          <c:out value="${lease.shortLeaseId}"/>
                        </span>
                      </div>
                      <div class="col-auto">
                        <span class="badge bg-secondary-lt text-secondary small">
                          <c:out value="${lease.ttl}"/>s
                        </span>
                      </div>
                    </div>
                  </div>
                </c:forEach>
              </div>
            </c:if>
            <c:if test="${empty leases}">
              <div class="text-muted small">目前無活躍租約</div>
            </c:if>
          </div>
        </div>
      </div>

      <%-- MongoDB 狀態 --%>
      <div class="col-md-4">
        <div class="card">
          <div class="card-header">
            <h3 class="card-title">
              <span class="avatar avatar-sm bg-success-lt text-success me-2">
                <i class="bi bi-database"></i>
              </span>
              MongoDB 連線狀態
            </h3>
          </div>
          <div class="card-body">
            <c:choose>
              <c:when test="${empty currentCred or currentCred.expired}">
                <div class="empty empty-sm">
                  <p class="empty-subtitle text-muted mb-3">尚未申請動態憑證</p>
                  <div class="empty-action">
                    <a href="${pageContext.request.contextPath}/creds" class="btn btn-sm btn-primary">
                      <i class="bi bi-key me-1"></i>申請動態憑證
                    </a>
                  </div>
                </div>
              </c:when>
              <c:otherwise>
                <dl class="row mb-3">
                  <dt class="col-4 text-muted small fw-normal">狀態</dt>
                  <dd class="col-8 mb-1">
                    <c:choose>
                      <c:when test="${not empty connStatus and connStatus.connected}">
                        <span class="d-flex align-items-center gap-1">
                          <span class="status-dot status-green"></span>
                          <span class="small">連線正常</span>
                          <span class="text-muted small">(<c:out value="${connStatus.pingMs}"/>ms)</span>
                        </span>
                      </c:when>
                      <c:otherwise>
                        <span class="d-flex align-items-center gap-1">
                          <span class="status-dot status-red"></span>
                          <span class="small">連線失敗</span>
                        </span>
                      </c:otherwise>
                    </c:choose>
                  </dd>

                  <dt class="col-4 text-muted small fw-normal">帳號</dt>
                  <dd class="col-8 small font-monospace text-truncate mb-1">
                    <c:out value="${currentCred.username}"/>
                  </dd>

                  <dt class="col-4 text-muted small fw-normal pt-1">憑證 TTL</dt>
                  <dd class="col-8 mb-0">
                    <span class="badge bg-info-lt text-info mb-1"
                          id="dashCredTtl"
                          data-ttl="${currentCred.remainingTtlSeconds}"
                          data-bar="dashCredTtlBar">
                      <c:out value="${currentCred.remainingTtlSeconds}"/>秒
                    </span>
                    <div class="progress progress-sm progress-track-info">
                      <div id="dashCredTtlBar" class="progress-bar bg-info" role="progressbar"
                           data-total="${currentCred.leaseDuration}"
                           style="width:${currentCred.remainingTtlSeconds * 100 / (currentCred.leaseDuration > 0 ? currentCred.leaseDuration : 1)}%">
                      </div>
                    </div>
                  </dd>
                </dl>

                <div class="d-grid gap-2">
                  <a href="${pageContext.request.contextPath}/data"
                     class="btn btn-sm btn-success">
                    <i class="bi bi-database-fill-up me-1"></i>開啟資料瀏覽器
                  </a>
                  <a href="${pageContext.request.contextPath}/creds"
                     class="btn btn-sm btn-outline-secondary">
                    <i class="bi bi-arrow-repeat me-1"></i>重新申請憑證
                  </a>
                </div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>

    </div><%-- /row-deck --%>

    <%-- 快速功能 --%>
    <div class="card">
      <div class="card-header">
        <h3 class="card-title">快速功能</h3>
      </div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-6 col-md-3">
            <a href="${pageContext.request.contextPath}/creds"
               class="card card-link card-link-pop text-center p-3 border">
              <div class="avatar avatar-lg bg-warning-lt text-warning mx-auto mb-2">
                <i class="bi bi-key-fill fs-4"></i>
              </div>
              <div class="small fw-semibold">申請動態憑證</div>
            </a>
          </div>
          <div class="col-6 col-md-3">
            <a href="${pageContext.request.contextPath}/leases"
               class="card card-link card-link-pop text-center p-3 border">
              <div class="avatar avatar-lg bg-primary-lt text-primary mx-auto mb-2">
                <i class="bi bi-hourglass-split fs-4"></i>
              </div>
              <div class="small fw-semibold">Lease 管理</div>
            </a>
          </div>
          <div class="col-6 col-md-3">
            <a href="${pageContext.request.contextPath}/data"
               class="card card-link card-link-pop text-center p-3 border">
              <div class="avatar avatar-lg bg-success-lt text-success mx-auto mb-2">
                <i class="bi bi-database fs-4"></i>
              </div>
              <div class="small fw-semibold">資料瀏覽器</div>
            </a>
          </div>
          <div class="col-6 col-md-3">
            <a href="${pageContext.request.contextPath}/audit"
               class="card card-link card-link-pop text-center p-3 border">
              <div class="avatar avatar-lg bg-secondary-lt text-secondary mx-auto mb-2">
                <i class="bi bi-journal-text fs-4"></i>
              </div>
              <div class="small fw-semibold">稽核日誌</div>
            </a>
          </div>
        </div>
      </div>
    </div>

  </div>
</div><%-- /page-body --%>

<%@ include file="_footer.jsp" %>
