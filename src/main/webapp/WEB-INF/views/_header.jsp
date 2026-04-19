<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
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

<header class="navbar navbar-expand-lg d-print-none">
  <div class="container-fluid">

    <a class="navbar-brand" href="${pageContext.request.contextPath}/dashboard">
      <i class="bi bi-shield-lock-fill text-warning me-2"></i>
      <span class="fw-bold">Vault MongoDB 展示</span>
    </a>

    <button class="navbar-toggler" type="button"
            data-bs-toggle="collapse" data-bs-target="#navbar-menu"
            aria-controls="navbar-menu" aria-expanded="false">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbar-menu">

      <ul class="navbar-nav">
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "dashboard"}'>active</c:if>"
             href="${pageContext.request.contextPath}/dashboard">
            <span class="nav-link-icon"><i class="bi bi-speedometer2"></i></span>
            <span class="nav-link-title">儀表板</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "creds"}'>active</c:if>"
             href="${pageContext.request.contextPath}/creds">
            <span class="nav-link-icon"><i class="bi bi-key-fill"></i></span>
            <span class="nav-link-title">動態憑證</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "leases"}'>active</c:if>"
             href="${pageContext.request.contextPath}/leases">
            <span class="nav-link-icon"><i class="bi bi-hourglass-split"></i></span>
            <span class="nav-link-title">Lease 管理</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "data"}'>active</c:if>"
             href="${pageContext.request.contextPath}/data">
            <span class="nav-link-icon"><i class="bi bi-database"></i></span>
            <span class="nav-link-title">資料瀏覽器</span>
          </a>
        </li>
        <li class="nav-item">
          <a class="nav-link <c:if test='${currentPage == "audit"}'>active</c:if>"
             href="${pageContext.request.contextPath}/audit">
            <span class="nav-link-icon"><i class="bi bi-journal-text"></i></span>
            <span class="nav-link-title">稽核日誌</span>
          </a>
        </li>
      </ul>

      <div class="navbar-nav flex-row order-lg-last ms-auto align-items-center gap-2">

        <%-- Token TTL --%>
        <c:if test="${not empty sessionScope.vaultToken}">
          <c:set var="remainTtl" value="${sessionScope.vaultToken.remainingTtlSeconds}"/>
          <c:set var="totalTtl"  value="${sessionScope.vaultToken.ttl}"/>
          <div class="d-none d-lg-block me-2" style="min-width:90px;">
            <div class="d-flex align-items-center justify-content-between mb-1">
              <span class="text-muted" style="font-size:0.7rem; letter-spacing:.04em; text-transform:uppercase;">Token TTL</span>
              <span id="tokenTtl"
                    data-ttl="${remainTtl}"
                    data-bar="tokenTtlBar"
                    class="badge badge-sm ms-1
                      <c:choose>
                        <c:when test='${remainTtl > 300}'>bg-success</c:when>
                        <c:when test='${remainTtl > 60}'>bg-warning text-dark</c:when>
                        <c:otherwise>bg-danger</c:otherwise>
                      </c:choose>"
                    style="font-size:0.65rem;">
                <c:out value="${remainTtl}"/>s
              </span>
            </div>
            <div class="progress" style="height:3px;">
              <div id="tokenTtlBar"
                   class="progress-bar
                     <c:choose>
                       <c:when test='${remainTtl > 300}'>bg-success</c:when>
                       <c:when test='${remainTtl > 60}'>bg-warning</c:when>
                       <c:otherwise>bg-danger</c:otherwise>
                     </c:choose>"
                   role="progressbar"
                   data-total="${totalTtl}"
                   style="width:${remainTtl * 100 / (totalTtl > 0 ? totalTtl : 1)}%">
              </div>
            </div>
          </div>
        </c:if>

        <%-- 使用者下拉選單 --%>
        <c:if test="${not empty sessionScope.vaultUsername}">
          <div class="nav-item dropdown">
            <a href="#" class="nav-link d-flex lh-1 text-reset p-0"
               data-bs-toggle="dropdown" aria-label="使用者選單">
              <span class="avatar avatar-sm bg-primary-lt text-primary">
                <i class="bi bi-person-fill"></i>
              </span>
              <div class="d-none d-xl-block ps-2 lh-1">
                <div class="fw-semibold" style="font-size:0.875rem; line-height:1.3;">
                  <c:out value="${sessionScope.vaultUsername}"/>
                </div>
                <div class="text-muted" style="font-size:0.72rem; margin-top:2px;">Vault 使用者</div>
              </div>
            </a>
            <div class="dropdown-menu dropdown-menu-end shadow-sm">
              <div class="dropdown-header small text-muted">
                <i class="bi bi-shield-check me-1"></i>已驗證身份
              </div>
              <div class="dropdown-divider m-0"></div>
              <form method="post" action="${pageContext.request.contextPath}/logout">
                <button type="submit" class="dropdown-item text-danger"
                        onclick="return confirm('確定要登出？')">
                  <i class="bi bi-box-arrow-right me-2"></i>登出
                </button>
              </form>
            </div>
          </div>
        </c:if>

      </div>
    </div>
  </div>
</header>

<div class="page-wrapper">
