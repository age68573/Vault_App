<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>404 — 頁面不存在</title>
  <link rel="stylesheet"
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
</head>
<body class="bg-light d-flex align-items-center min-vh-100">
<div class="container text-center">
  <h1 class="display-1 text-muted">404</h1>
  <h4>找不到此頁面</h4>
  <p class="text-muted">您要求的資源不存在或已移除。</p>
  <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-primary">
    返回儀表板
  </a>
</div>
</body>
</html>
