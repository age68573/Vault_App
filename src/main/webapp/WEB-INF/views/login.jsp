<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>登入 — Vault MongoDB 動態憑證展示</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/tabler.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/bootstrap-icons.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/app.css">
</head>
<body class="d-flex flex-column antialiased">
<div class="page page-center">
  <div class="container-tight py-4">

    <div class="text-center mb-4">
      <a class="navbar-brand navbar-brand-autodark">
        <i class="bi bi-shield-lock-fill text-warning" style="font-size:2.5rem;"></i>
      </a>
      <h2 class="mt-2 fw-bold">HashiCorp Vault</h2>
      <p class="text-muted">MongoDB 動態憑證展示系統</p>
    </div>

    <c:if test="${not empty error}">
      <div class="alert alert-danger mb-3" role="alert">
        <div class="d-flex">
          <div><i class="bi bi-exclamation-triangle-fill me-2"></i></div>
          <div><c:out value="${error}"/></div>
        </div>
      </div>
    </c:if>

    <div class="card card-md">
      <div class="card-body">
        <h2 class="h2 text-center mb-4">登入帳號</h2>
        <form method="post" action="${pageContext.request.contextPath}/login" autocomplete="off">

          <div class="mb-3">
            <label class="form-label" for="username">使用者名稱</label>
            <input type="text" class="form-control" id="username" name="username"
                   placeholder="Vault 使用者名稱"
                   value="<c:out value='${param.username}'/>"
                   required autofocus autocomplete="username">
          </div>

          <div class="mb-2">
            <label class="form-label" for="password">密碼</label>
            <input type="password" class="form-control" id="password" name="password"
                   placeholder="Vault 密碼"
                   required autocomplete="current-password">
          </div>

          <div class="form-footer">
            <button type="submit" class="btn btn-primary w-100">
              <i class="bi bi-shield-check me-1"></i>登入 Vault
            </button>
          </div>
        </form>
      </div>
    </div>

    <div class="text-center text-muted mt-3 small">
      <i class="bi bi-info-circle me-1"></i>
      登入後將向 Vault 申請短效期 MongoDB 動態憑證
    </div>

  </div>
</div>
<script src="${pageContext.request.contextPath}/static/js/tabler.min.js"></script>
</body>
</html>
