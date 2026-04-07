<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>500 — 伺服器錯誤</title>
  <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
</head>
<body class="bg-light d-flex align-items-center min-vh-100">
<div class="container text-center">
  <h1 class="display-1 text-danger">500</h1>
  <h4>伺服器發生錯誤</h4>
  <p class="text-muted">系統處理請求時發生未預期的錯誤，請稍後再試。</p>
  <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-primary">
    返回儀表板
  </a>
</div>
</body>
</html>
