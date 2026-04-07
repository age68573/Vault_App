<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>登入 Vault &mdash; MongoDB 動態憑證展示</title>
  <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
  <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/app.css">
</head>
<body class="bg-light d-flex align-items-center min-vh-100">

<div class="container">
  <div class="row justify-content-center">
    <div class="col-md-5 col-lg-4">

      <div class="text-center mb-4">
        <i class="bi bi-shield-lock-fill text-warning" style="font-size:3rem;"></i>
        <h2 class="mt-2 fw-bold">HashiCorp Vault</h2>
        <p class="text-muted">MongoDB 動態憑證展示系統</p>
      </div>

      <%-- 錯誤訊息 --%>
      <c:if test="${not empty error}">
        <div class="alert alert-danger d-flex align-items-center" role="alert">
          <i class="bi bi-exclamation-triangle-fill me-2"></i>
          <span><c:out value="${error}"/></span>
        </div>
      </c:if>

      <div class="card shadow-sm">
        <div class="card-header bg-dark text-white">
          <i class="bi bi-person-lock me-1"></i>使用 Vault 帳號登入
        </div>
        <div class="card-body p-4">
          <form method="post" action="${pageContext.request.contextPath}/login">

            <div class="mb-3">
              <label for="username" class="form-label fw-semibold">
                <i class="bi bi-person me-1"></i>使用者名稱
              </label>
              <input type="text" class="form-control" id="username" name="username"
                     placeholder="輸入 Vault 使用者名稱"
                     value="<c:out value='${param.username}'/>"
                     required autofocus autocomplete="username">
            </div>

            <div class="mb-4">
              <label for="password" class="form-label fw-semibold">
                <i class="bi bi-key me-1"></i>密碼
              </label>
              <input type="password" class="form-control" id="password" name="password"
                     placeholder="輸入 Vault 密碼"
                     required autocomplete="current-password">
            </div>

            <div class="d-grid">
              <button type="submit" class="btn btn-warning fw-bold">
                <i class="bi bi-shield-check me-1"></i>登入 Vault
              </button>
            </div>
          </form>
        </div>
      </div>

      <div class="card mt-3 border-0 bg-transparent">
        <div class="card-body small text-muted text-center">
          <i class="bi bi-info-circle me-1"></i>
          登入後系統將向 Vault 申請動態 MongoDB 憑證<br>
          每次申請的帳號密碼均不同且具有有限存活時間
        </div>
      </div>

    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
