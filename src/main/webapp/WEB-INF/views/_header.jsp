<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
  共用頁首片段：Tabler 頂部導覽列
  使用方式：<%@ include file="_header.jsp" %>
  需要 Session 中存在 vaultUsername 與 vaultToken。
--%>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="context-path" content="${pageContext.request.contextPath}">
  <title><c:out value="${pageTitle}" default="Vault MongoDB 動態憑證展示"/></title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/tabler.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/bootstrap-icons.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/app.css">
</head>
<body class="antialiased">
<div class="wrapper">

<header class="navbar navbar-expand-lg navbar-dark" style="background-color:#1a1a2e;">
  <div class="container-fluid">
    <a class="navbar-brand fw-bold" href="${pageContext.request.contextPath}/dashboard">
      <i class="bi bi-shield-lock-fill text-warning me-2"></i>Vault MongoDB 展示
    </a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse"
            data-bs-target="#navbarNav" aria-controls="navbarNav"
            aria-expanded="false" aria-label="切換導覽">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav me-auto">
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "dashboard"}'>active</c:if>"
             href="${pageContext.request.contextPath}/dashboard">
            <i class="bi bi-speedometer2 me-1"></i>儀表板
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "creds"}'>active</c:if>"
             href="${pageContext.request.contextPath}/creds">
            <i class="bi bi-key-fill me-1"></i>動態憑證
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "leases"}'>active</c:if>"
             href="${pageContext.request.contextPath}/leases">
            <i class="bi bi-hourglass-split me-1"></i>Lease 管理
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "data"}'>active</c:if>"
             href="${pageContext.request.contextPath}/data">
            <i class="bi bi-database me-1"></i>資料瀏覽器
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "audit"}'>active</c:if>"
             href="${pageContext.request.contextPath}/audit">
            <i class="bi bi-journal-text me-1"></i>稽核日誌
          </a>
        </li>
      </ul>

      <div class="navbar-nav align-items-center">
        <%-- Token TTL 倒數顯示 --%>
        <c:if test="${not empty sessionScope.vaultToken}">
          <span class="navbar-text me-3 d-flex align-items-center gap-2">
            <i class="bi bi-person-circle"></i>
            <c:out value="${sessionScope.vaultUsername}"/>
            <span class="vr" style="opacity:.4;"></span>
            <i class="bi bi-clock"></i>
            TTL：<span id="tokenTtl"
                       data-ttl="${sessionScope.vaultToken.remainingTtlSeconds}"
                       data-bar="tokenTtlBar"
                       class="badge bg-success">
              <c:out value="${sessionScope.vaultToken.remainingTtlSeconds}"/>秒
            </span>
            <div class="progress ms-1" style="height:4px;width:72px;">
              <div id="tokenTtlBar"
                   class="progress-bar bg-success"
                   role="progressbar"
                   data-total="${sessionScope.vaultToken.ttl}"
                   style="width:${sessionScope.vaultToken.remainingTtlSeconds * 100 / (sessionScope.vaultToken.ttl > 0 ? sessionScope.vaultToken.ttl : 1)}%">
              </div>
            </div>
          </span>
        </c:if>

        <%-- 登出按鈕 --%>
        <form method="post" action="${pageContext.request.contextPath}/logout"
              class="d-inline">
          <button type="submit" class="btn btn-sm btn-outline-light"
                  onclick="return confirm('確定要登出？Token 底下的 Lease 將繼續有效直到 TTL 到期。')">
            <i class="bi bi-box-arrow-right me-1"></i>登出
          </button>
        </form>
      </div>
    </div>
  </div>
</header>

<div class="page-wrapper">
