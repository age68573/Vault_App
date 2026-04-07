<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="動態憑證 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="creds" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="container-xl py-4">

  <div class="page-header d-print-none mb-4">
    <div class="row align-items-center">
      <div class="col">
        <h2 class="page-title">
          <i class="bi bi-key-fill me-2 text-warning"></i>MongoDB 動態憑證
        </h2>
      </div>
    </div>
  </div>

  <%-- 成功提示 --%>
  <c:if test="${not empty successMsg}">
    <div class="alert alert-success alert-dismissible fade show mb-4" role="alert">
      <i class="bi bi-check-circle-fill me-1"></i>動態憑證申請成功！帳號密碼已顯示於下方。
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>

  <%-- 錯誤提示 --%>
  <c:if test="${not empty error}">
    <div class="alert alert-danger alert-dismissible fade show mb-4" role="alert">
      <i class="bi bi-exclamation-triangle-fill me-1"></i><c:out value="${error}"/>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>

  <div class="row g-4">

    <%-- 目前有效憑證 --%>
    <div class="col-lg-7">
      <div class="card h-100">
        <div class="card-header" style="background:#1a1a2e; color:#fff;">
          <h3 class="card-title mb-0">
            <i class="bi bi-card-checklist me-2"></i>目前有效的動態憑證
          </h3>
        </div>
        <div class="card-body">
          <c:choose>
            <c:when test="${not empty currentCred and not currentCred.expired}">
              <table class="table table-bordered mb-4">
                <tbody>
                  <tr>
                    <th class="table-light w-30" style="width:30%">Lease ID</th>
                    <td class="font-monospace small text-break">
                      <span title="${currentCred.leaseId}">
                        <c:out value="${currentCred.leaseId}"/>
                      </span>
                    </td>
                  </tr>
                  <tr>
                    <th class="table-light">使用者名稱</th>
                    <td class="font-monospace fw-bold text-primary">
                      <c:out value="${currentCred.username}"/>
                    </td>
                  </tr>
                  <tr>
                    <th class="table-light">密碼</th>
                    <td>
                      <div class="input-group">
                        <input type="password" class="form-control form-control-sm font-monospace"
                               id="credPassword" readonly
                               value="<c:out value='${currentCred.password}'/>">
                        <button class="btn btn-sm btn-outline-secondary"
                                type="button" onclick="togglePassword()">
                          <i class="bi bi-eye" id="eyeIcon"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-primary"
                                type="button"
                                onclick="copyToClipboard('credPassword')">
                          <i class="bi bi-clipboard"></i>
                        </button>
                      </div>
                      <small class="text-muted">⚠ 密碼僅於此處顯示一次</small>
                    </td>
                  </tr>
                  <tr>
                    <th class="table-light">存活時間</th>
                    <td><c:out value="${currentCred.leaseDuration}"/>秒</td>
                  </tr>
                  <tr>
                    <th class="table-light" style="vertical-align:top;padding-top:10px;">剩餘時間</th>
                    <td>
                      <span id="credTtlBadge"
                            class="badge bg-success fs-6 mb-2"
                            data-ttl="${currentCred.remainingTtlSeconds}"
                            data-bar="credTtlBar">
                        <c:out value="${currentCred.remainingTtlSeconds}"/>秒
                      </span>
                      <div class="progress progress-sm">
                        <div id="credTtlBar"
                             class="progress-bar bg-success"
                             role="progressbar"
                             data-total="${currentCred.leaseDuration}"
                             style="width:${currentCred.remainingTtlSeconds * 100 / (currentCred.leaseDuration > 0 ? currentCred.leaseDuration : 1)}%">
                        </div>
                      </div>
                    </td>
                  </tr>
                  <tr>
                    <th class="table-light">可續期</th>
                    <td>
                      <c:choose>
                        <c:when test="${currentCred.renewable}">
                          <span class="badge bg-success">是</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge bg-secondary">否</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                  </tr>
                </tbody>
              </table>

              <div class="d-flex gap-2">
                <a href="${pageContext.request.contextPath}/leases"
                   class="btn btn-sm btn-outline-primary">
                  <i class="bi bi-hourglass-split me-1"></i>管理 Lease
                </a>
                <a href="${pageContext.request.contextPath}/data"
                   class="btn btn-sm btn-outline-success">
                  <i class="bi bi-database me-1"></i>使用此憑證操作資料
                </a>
              </div>
            </c:when>
            <c:otherwise>
              <div class="text-center py-4 text-muted">
                <i class="bi bi-key text-secondary" style="font-size:3rem;"></i>
                <p class="mt-2">尚未申請動態憑證，或憑證已過期</p>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>

    <%-- 申請新憑證 --%>
    <div class="col-lg-5">
      <div class="card mb-4">
        <div class="card-header bg-warning-lt">
          <h3 class="card-title mb-0">
            <i class="bi bi-plus-circle me-2 text-warning"></i>申請新的動態憑證
          </h3>
        </div>
        <div class="card-body">
          <div class="alert alert-info small">
            <i class="bi bi-info-circle me-1"></i>
            每次申請將向 Vault 產生全新的 MongoDB 帳號與密碼，
            並建立對應的 Lease。前一筆憑證不會自動撤銷。
          </div>
          <table class="table table-sm table-borderless mb-3">
            <tr>
              <td class="text-muted small">Vault 角色</td>
              <td class="font-monospace fw-bold"><c:out value="${vaultRole}"/></td>
            </tr>
            <tr>
              <td class="text-muted small">登入使用者</td>
              <td><c:out value="${username}"/></td>
            </tr>
          </table>
          <form method="post" action="${pageContext.request.contextPath}/creds">
            <div class="d-grid">
              <button type="submit" class="btn btn-warning fw-bold">
                <i class="bi bi-key-fill me-1"></i>申請 MongoDB 動態憑證
              </button>
            </div>
          </form>
        </div>
      </div>

      <%-- 說明區塊 --%>
      <div class="accordion" id="howItWorks">
        <div class="accordion-item">
          <h2 class="accordion-header">
            <button class="accordion-button collapsed" type="button"
                    data-bs-toggle="collapse" data-bs-target="#collapseHow">
              <i class="bi bi-question-circle me-2"></i>動態憑證如何運作？
            </button>
          </h2>
          <div id="collapseHow" class="accordion-collapse collapse">
            <div class="accordion-body small text-muted">
              <ol class="mb-0">
                <li class="mb-1">使用者向 Vault 的 <strong>Database Secrets Engine</strong> 發送請求</li>
                <li class="mb-1">Vault 在 MongoDB 中建立一個<strong>全新的臨時帳號</strong>，具有角色所定義的權限</li>
                <li class="mb-1">憑證連同 <strong>Lease ID</strong> 回傳給應用程式使用</li>
                <li class="mb-1">Lease 到期後，Vault <strong>自動刪除</strong>該 MongoDB 帳號</li>
                <li class="mb-0">可透過 Lease Manager 手動<strong>撤銷</strong>或<strong>續期</strong></li>
              </ol>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div><%-- /row --%>
</div>

<%@ include file="_footer.jsp" %>
<script>
function togglePassword() {
  const input = document.getElementById('credPassword');
  const icon  = document.getElementById('eyeIcon');
  if (input.type === 'password') {
    input.type = 'text';
    icon.className = 'bi bi-eye-slash';
  } else {
    input.type = 'password';
    icon.className = 'bi bi-eye';
  }
}
function copyToClipboard(id) {
  const el = document.getElementById(id);
  navigator.clipboard.writeText(el.value).then(() => {
    alert('已複製到剪貼簿');
  });
}
</script>
