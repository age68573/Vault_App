<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>404 — 頁面不存在</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/tabler.min.css">
</head>
<body class="antialiased d-flex flex-column">
<div class="page page-center">
<div class="container-tight text-center">
  <h1 class="display-1 text-muted">404</h1>
  <h4>找不到此頁面</h4>
  <p class="text-muted">您要求的資源不存在或已移除。</p>
  <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-primary">
    返回儀表板
  </a>
</div>
</div>
</body>
</html>
