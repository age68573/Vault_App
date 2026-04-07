<%@ page contentType="text/html;charset=UTF-8" language="java" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <title>500 — 伺服器錯誤</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/tabler.min.css">
</head>
<body class="antialiased d-flex flex-column">
<div class="page page-center">
<div class="container-tight text-center">
  <h1 class="display-1 text-danger">500</h1>
  <h4>伺服器發生錯誤</h4>
  <p class="text-muted">系統處理請求時發生未預期的錯誤，請稍後再試。</p>
  <a href="${pageContext.request.contextPath}/dashboard" class="btn btn-primary">
    返回儀表板
  </a>
</div>
</div>
</body>
</html>
