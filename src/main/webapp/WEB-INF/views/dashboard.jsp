<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="儀表板 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="dashboard" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="container-fluid py-4">
  <div class="d-flex align-items-center mb-4">
    <h4 class="mb-0 fw-bold"><i class="bi bi-speedometer2 me-2 text-primary"></i>儀表板</h4>
    <a href="${pageContext.request.contextPath}/dashboard"
       class="btn btn-sm btn-outline-secondary ms-3">
      <i class="bi bi-arrow-clockwise me-1"></i>重新整理
    </a>
  </div>

  <%-- Token 錯誤提示 --%>
  <c:if test="${not empty tokenError}">
    <div class="alert alert-warning"><i class="bi bi-exclamation-triangle me-1"></i>
      <c:out value="${tokenError}"/></div>
  </c:if>

  <div class="row g-4">

    <%-- 卡片 1：Vault Token 資訊 --%>
    <div class="col-md-4">
      <div class="card h-100 shadow-sm border-0">
        <div class="card-header bg-dark text-white fw-semibold">
          <i class="bi bi-shield-check me-2"></i>Vault Token 資訊
        </div>
        <div class="card-body">
          <c:choose>
            <c:when test="${not empty token}">
              <table class="table table-sm table-borderless mb-0">
                <tbody>
                  <tr>
                    <td class="text-muted small">存取器</td>
                    <td class="small font-monospace text-truncate" style="max-width:150px;"
                        title="${token.accessor}">
                      <c:out value="${token.accessor}"/>
                    </td>
                  </tr>
                  <tr>
                    <td class="text-muted small">政策</td>
                    <td class="small">
                      <c:forEach var="p" items="${token.policies}" varStatus="s">
                        <c:out value="${p}"/><c:if test="${!s.last}">, </c:if>
                      </c:forEach>
                    </td>
                  </tr>
                  <tr>
                    <td class="text-muted small">可續期</td>
                    <td>
                      <c:choose>
                        <c:when test="${token.renewable}">
                          <span class="badge bg-success">是</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-secondary">否</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                  </tr>
                  <tr>
                    <td class="text-muted small" style="vertical-align:top;padding-top:6px;">剩餘 TTL</td>
                    <td>
                      <c:set var="ttl"      value="${token.remainingTtlSeconds}"/>
                      <c:set var="totalTtl" value="${token.ttl}"/>
                      <%-- 時間文字徽章 --%>
                      <c:choose>
                        <c:when test="${ttl > 300}">
                          <span class="badge bg-success fs-6 mb-2"
                                id="dashTtl" data-ttl="${ttl}">
                            <c:out value="${ttl}"/>秒
                          </span>
                        </c:when>
                        <c:when test="${ttl > 60}">
                          <span class="badge bg-warning text-dark fs-6 mb-2"
                                id="dashTtl" data-ttl="${ttl}">
                            <c:out value="${ttl}"/>秒
                          </span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-danger fs-6 mb-2"
                                id="dashTtl" data-ttl="${ttl}">
                            <c:out value="${ttl}"/>秒（即將到期）
                          </span>
                        </c:otherwise>
                      </c:choose>
                      <%-- 進度條 --%>
                      <div class="progress" style="height:8px;"
                           title="剩餘 ${ttl} 秒 / 共 ${totalTtl} 秒">
                        <div id="dashTtlBar"
                             class="progress-bar"
                             role="progressbar"
                             data-total="${totalTtl}"
                             style="width:${ttl * 100 / (totalTtl > 0 ? totalTtl : 1)}%">
                        </div>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </c:when>
            <c:otherwise>
              <p class="text-muted small">無法取得 Token 資訊</p>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>

    <%-- 卡片 2：活躍 Lease --%>
    <div class="col-md-4">
      <div class="card h-100 shadow-sm border-0">
        <div class="card-header bg-dark text-white fw-semibold">
          <i class="bi bi-hourglass-split me-2"></i>活躍 Lease
        </div>
        <div class="card-body">
          <div class="text-center mb-3">
            <span class="display-5 fw-bold text-primary">
              <c:out value="${leaseCount}"/>
            </span>
            <p class="text-muted small mb-0">筆活躍租約</p>
          </div>

          <c:if test="${not empty leases}">
            <ul class="list-group list-group-flush small">
              <c:forEach var="lease" items="${leases}" end="2">
                <li class="list-group-item px-0 py-1">
                  <span class="font-monospace text-truncate d-block"
                        style="max-width:200px;"
                        title="${lease.leaseId}">
                    <c:out value="${lease.shortLeaseId}"/>
                  </span>
                  <span class="badge bg-secondary">TTL: <c:out value="${lease.ttl}"/>s</span>
                </li>
              </c:forEach>
            </ul>
          </c:if>

          <div class="mt-3">
            <a href="${pageContext.request.contextPath}/leases"
               class="btn btn-sm btn-outline-primary w-100">
              <i class="bi bi-list-ul me-1"></i>管理所有 Lease
            </a>
          </div>
        </div>
      </div>
    </div>

    <%-- 卡片 3：MongoDB 連線狀態 --%>
    <div class="col-md-4">
      <div class="card h-100 shadow-sm border-0">
        <div class="card-header bg-dark text-white fw-semibold">
          <i class="bi bi-database me-2"></i>MongoDB 連線狀態
        </div>
        <div class="card-body">
          <c:choose>
            <c:when test="${empty currentCred or currentCred.expired}">
              <div class="text-center py-2">
                <i class="bi bi-database-x text-secondary" style="font-size:2rem;"></i>
                <p class="text-muted small mt-2 mb-3">尚未申請動態憑證</p>
                <a href="${pageContext.request.contextPath}/creds"
                   class="btn btn-sm btn-warning">
                  <i class="bi bi-key me-1"></i>申請動態憑證
                </a>
              </div>
            </c:when>
            <c:otherwise>
              <table class="table table-sm table-borderless mb-3">
                <tr>
                  <td class="text-muted small">狀態</td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty connStatus and connStatus.connected}">
                        <span class="badge bg-success">
                          <i class="bi bi-check-circle me-1"></i>連線正常
                        </span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge bg-danger">
                          <i class="bi bi-x-circle me-1"></i>連線失敗
                        </span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
                <c:if test="${not empty connStatus and connStatus.connected}">
                  <tr>
                    <td class="text-muted small">延遲</td>
                    <td class="small"><c:out value="${connStatus.pingMs}"/>ms</td>
                  </tr>
                </c:if>
                <tr>
                  <td class="text-muted small">帳號</td>
                  <td class="small font-monospace"><c:out value="${currentCred.username}"/></td>
                </tr>
                <tr>
                  <td class="text-muted small">憑證 TTL</td>
                  <td class="small">
                    <span class="badge bg-info text-dark"
                          data-ttl="${currentCred.remainingTtlSeconds}">
                      <c:out value="${currentCred.remainingTtlSeconds}"/>秒
                    </span>
                  </td>
                </tr>
              </table>
              <div class="d-grid gap-2">
                <a href="${pageContext.request.contextPath}/data"
                   class="btn btn-sm btn-outline-success">
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

  </div><%-- /row --%>

  <%-- 快速連結 --%>
  <div class="row mt-4">
    <div class="col-12">
      <div class="card shadow-sm border-0">
        <div class="card-header bg-secondary text-white fw-semibold">
          <i class="bi bi-grid-3x2-gap me-2"></i>快速功能
        </div>
        <div class="card-body">
          <div class="row g-3">
            <div class="col-6 col-md-3">
              <a href="${pageContext.request.contextPath}/creds"
                 class="btn btn-outline-warning w-100 py-3">
                <i class="bi bi-key-fill d-block mb-1" style="font-size:1.5rem;"></i>
                申請動態憑證
              </a>
            </div>
            <div class="col-6 col-md-3">
              <a href="${pageContext.request.contextPath}/leases"
                 class="btn btn-outline-primary w-100 py-3">
                <i class="bi bi-hourglass-split d-block mb-1" style="font-size:1.5rem;"></i>
                Lease 管理
              </a>
            </div>
            <div class="col-6 col-md-3">
              <a href="${pageContext.request.contextPath}/data"
                 class="btn btn-outline-success w-100 py-3">
                <i class="bi bi-database d-block mb-1" style="font-size:1.5rem;"></i>
                資料瀏覽器
              </a>
            </div>
            <div class="col-6 col-md-3">
              <a href="${pageContext.request.contextPath}/audit"
                 class="btn btn-outline-secondary w-100 py-3">
                <i class="bi bi-journal-text d-block mb-1" style="font-size:1.5rem;"></i>
                稽核日誌
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

</div><%-- /container-fluid --%>

<%@ include file="_footer.jsp" %>
