<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="動態憑證 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="creds" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="page-header d-print-none">
  <div class="container-xl">
    <div class="row g-2 align-items-center">
      <div class="col">
        <h2 class="page-title">MongoDB 動態憑證</h2>
        <div class="text-muted mt-1 small">向 Vault Database Secrets Engine 申請短效期憑證</div>
      </div>
    </div>
  </div>
</div>

<div class="page-body">
  <div class="container-xl">

    <c:if test="${not empty successMsg}">
      <div class="alert alert-success alert-dismissible mb-4" role="alert">
        <div class="d-flex">
          <div><i class="bi bi-check-circle-fill me-2"></i></div>
          <div>動態憑證申請成功！帳號密碼已顯示於下方。</div>
        </div>
        <a class="btn-close" data-bs-dismiss="alert" aria-label="close"></a>
      </div>
    </c:if>

    <c:if test="${not empty error}">
      <div class="alert alert-danger alert-dismissible mb-4" role="alert">
        <div class="d-flex">
          <div><i class="bi bi-exclamation-triangle-fill me-2"></i></div>
          <div><c:out value="${error}"/></div>
        </div>
        <a class="btn-close" data-bs-dismiss="alert" aria-label="close"></a>
      </div>
    </c:if>

    <div class="row row-cards">

      <%-- 目前憑證 --%>
      <div class="col-lg-7">
        <div class="card">
          <div class="card-header">
            <h3 class="card-title">目前有效的動態憑證</h3>
          </div>
          <div class="card-body">
            <c:choose>
              <c:when test="${not empty currentCred and not currentCred.expired}">

                <div class="mb-3">
                  <label class="form-label text-muted small">Lease ID</label>
                  <div class="input-group">
                    <span class="form-control font-monospace small text-muted text-truncate"
                          title="${currentCred.leaseId}">
                      <c:out value="${currentCred.leaseId}"/>
                    </span>
                  </div>
                </div>

                <div class="mb-3">
                  <label class="form-label text-muted small">使用者名稱</label>
                  <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-person"></i></span>
                    <input type="text" class="form-control font-monospace fw-bold text-primary"
                           readonly value="<c:out value='${currentCred.username}'/>">
                  </div>
                </div>

                <div class="mb-3">
                  <label class="form-label text-muted small">密碼
                    <span class="ms-1 text-warning small">⚠ 僅顯示一次</span>
                  </label>
                  <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-key"></i></span>
                    <input type="password" class="form-control font-monospace"
                           id="credPassword" readonly
                           value="<c:out value='${currentCred.password}'/>">
                    <button class="btn btn-outline-secondary" type="button" onclick="togglePassword()">
                      <i class="bi bi-eye" id="eyeIcon"></i>
                    </button>
                    <button class="btn btn-outline-primary" type="button"
                            onclick="copyToClipboard('credPassword')"
                            title="複製密碼">
                      <i class="bi bi-clipboard"></i>
                    </button>
                  </div>
                </div>

                <div class="row mb-3">
                  <div class="col-6">
                    <label class="form-label text-muted small">存活時間</label>
                    <div class="text-body"><c:out value="${currentCred.leaseDuration}"/>秒</div>
                  </div>
                  <div class="col-6">
                    <label class="form-label text-muted small">可續期</label>
                    <div>
                      <c:choose>
                        <c:when test="${currentCred.renewable}">
                          <span class="badge bg-success-lt text-success">是</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-secondary-lt text-secondary">否</span>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </div>
                </div>

                <div class="mb-1">
                  <label class="form-label text-muted small d-flex justify-content-between">
                    剩餘時間
                    <span id="credTtlBadge"
                          class="badge bg-success"
                          data-ttl="${currentCred.remainingTtlSeconds}"
                          data-bar="credTtlBar">
                      <c:out value="${currentCred.remainingTtlSeconds}"/>秒
                    </span>
                  </label>
                  <div class="progress progress-sm">
                    <div id="credTtlBar" class="progress-bar bg-success" role="progressbar"
                         data-total="${currentCred.leaseDuration}"
                         style="width:${currentCred.remainingTtlSeconds * 100 / (currentCred.leaseDuration > 0 ? currentCred.leaseDuration : 1)}%">
                    </div>
                  </div>
                </div>

              </c:when>
              <c:otherwise>
                <div class="empty">
                  <div class="empty-icon">
                    <i class="bi bi-key" style="font-size:2.5rem; color:var(--tblr-secondary);"></i>
                  </div>
                  <p class="empty-title">尚未申請動態憑證</p>
                  <p class="empty-subtitle text-muted">請從右側申請新的動態憑證</p>
                </div>
              </c:otherwise>
            </c:choose>
          </div>
          <c:if test="${not empty currentCred and not currentCred.expired}">
            <div class="card-footer">
              <div class="d-flex gap-2">
                <a href="${pageContext.request.contextPath}/leases"
                   class="btn btn-sm btn-outline-primary">
                  <i class="bi bi-hourglass-split me-1"></i>管理 Lease
                </a>
                <a href="${pageContext.request.contextPath}/data"
                   class="btn btn-sm btn-success">
                  <i class="bi bi-database me-1"></i>使用此憑證操作資料
                </a>
              </div>
            </div>
          </c:if>
        </div>
      </div>

      <%-- 申請面板 --%>
      <div class="col-lg-5">
        <div class="card mb-3">
          <div class="card-header">
            <h3 class="card-title">申請新的動態憑證</h3>
          </div>
          <div class="card-body">
            <div class="alert alert-info mb-3">
              <div class="d-flex">
                <div><i class="bi bi-info-circle me-2"></i></div>
                <div class="small">
                  每次申請將向 Vault 產生全新的 MongoDB 帳號與密碼，前一筆憑證不會自動撤銷。
                </div>
              </div>
            </div>
            <dl class="row mb-3">
              <dt class="col-5 text-muted small fw-normal">Vault 角色</dt>
              <dd class="col-7 font-monospace fw-bold small"><c:out value="${vaultRole}"/></dd>
              <dt class="col-5 text-muted small fw-normal">登入使用者</dt>
              <dd class="col-7 small"><c:out value="${username}"/></dd>
            </dl>
            <form method="post" action="${pageContext.request.contextPath}/creds">
              <button type="submit" class="btn btn-primary w-100">
                <i class="bi bi-key-fill me-1"></i>申請 MongoDB 動態憑證
              </button>
            </form>
          </div>
        </div>

        <%-- 說明 --%>
        <div class="accordion" id="howItWorks">
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button class="accordion-button collapsed" type="button"
                      data-bs-toggle="collapse" data-bs-target="#collapseHow">
                <i class="bi bi-question-circle me-2 text-muted"></i>動態憑證如何運作？
              </button>
            </h2>
            <div id="collapseHow" class="accordion-collapse collapse">
              <div class="accordion-body small text-muted">
                <ol class="mb-0 ps-3">
                  <li class="mb-1">向 Vault <strong>Database Secrets Engine</strong> 發出請求</li>
                  <li class="mb-1">Vault 在 MongoDB 建立一個<strong>全新的臨時帳號</strong></li>
                  <li class="mb-1">憑證連同 <strong>Lease ID</strong> 回傳給應用程式</li>
                  <li class="mb-1">Lease 到期後 Vault <strong>自動刪除</strong>該帳號</li>
                  <li class="mb-0">可透過 Lease Manager 手動<strong>撤銷</strong>或<strong>續期</strong></li>
                </ol>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</div><%-- /page-body --%>

<%@ include file="_footer.jsp" %>
<script>
function togglePassword() {
  const input = document.getElementById('credPassword');
  const icon  = document.getElementById('eyeIcon');
  input.type = input.type === 'password' ? 'text' : 'password';
  icon.className = input.type === 'password' ? 'bi bi-eye' : 'bi bi-eye-slash';
}
function copyToClipboard(id) {
  navigator.clipboard.writeText(document.getElementById(id).value)
    .then(() => alert('已複製到剪貼簿'));
}
</script>
