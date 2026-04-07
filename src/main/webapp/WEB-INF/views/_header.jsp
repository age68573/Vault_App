<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%--
  共用頁首片段：Bootstrap 5 導覽列
  使用方式：<%@ include file="_header.jsp" %>
  需要 Session 中存在 vaultUsername 與 vaultToken。
--%>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><c:out value="${pageTitle}" default="Vault MongoDB 動態憑證展示"/></title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/app.css">
</head>
<body>

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container-fluid">
    <a class="navbar-brand fw-bold" href="${pageContext.request.contextPath}/dashboard">
      <i class="bi bi-shield-lock-fill text-warning me-2"></i>Vault MongoDB 展示
    </a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse"
            data-bs-target="#navbarNav">
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
          <span class="navbar-text me-3">
            <i class="bi bi-person-circle me-1"></i>
            <c:out value="${sessionScope.vaultUsername}"/>
            &nbsp;|&nbsp;
            <i class="bi bi-clock me-1"></i>
            TTL：<span id="tokenTtl"
                       data-ttl="${sessionScope.vaultToken.remainingTtlSeconds}"
                       class="badge bg-success">
              <c:out value="${sessionScope.vaultToken.remainingTtlSeconds}"/>秒
            </span>
          </span>
        </c:if>

        <%-- 登出按鈕 --%>
        <form method="post" action="${pageContext.request.contextPath}/logout"
              class="d-inline" id="logoutForm">
          <button type="submit" class="btn btn-sm btn-outline-light"
                  onclick="return confirm('確定要登出並撤銷 Vault Token？')">
            <i class="bi bi-box-arrow-right me-1"></i>登出
          </button>
        </form>
      </div>
    </div>
  </div>
</nav>
