<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="context-path" content="${pageContext.request.contextPath}">
  <title><c:out value="${pageTitle}" default="Vault MongoDB 動態憑證展示"/></title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/tabler.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/bootstrap-icons.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/static/css/app.css">
</head>
<body class="antialiased" style="font-family:'Inter',-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
<div class="wrapper">

<header class="navbar navbar-expand-lg d-print-none">
  <div class="container-fluid" style="height:48px; padding:0 20px;">

    <%-- Brand --%>
    <a class="navbar-brand" href="${pageContext.request.contextPath}/dashboard"
       style="display:flex; align-items:center; gap:8px; margin-right:20px; flex-shrink:0;">
      <i class="bi bi-shield-lock-fill" style="font-size:1.2rem; color:#f59f00;"></i>
      <span style="font-weight:700; color:#1d2433; font-size:13px; white-space:nowrap;">Vault MongoDB 展示</span>
    </a>

    <button class="navbar-toggler" type="button"
            data-bs-toggle="collapse" data-bs-target="#navbar-menu"
            aria-controls="navbar-menu" aria-expanded="false"
            style="border-color:#e2e6ec;">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbar-menu"
         style="display:flex; align-items:center; flex:1; min-width:0;">

      <%-- Nav Links — pill style --%>
      <ul class="navbar-nav" style="display:flex; flex-direction:row; align-items:center; flex:1; min-width:0; gap:1px; flex-wrap:nowrap;">
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

      <%-- Right side: Token TTL + User (same background as navbar) --%>
      <div style="display:flex; align-items:center; gap:12px; margin-left:16px; flex-shrink:0;">

        <%-- Token TTL widget --%>
        <c:if test="${not empty sessionScope.vaultToken}">
          <c:set var="remainTtl" value="${sessionScope.vaultToken.remainingTtlSeconds}"/>
          <c:set var="totalTtl"  value="${sessionScope.vaultToken.ttl}"/>
          <c:set var="ttlPct"    value="${remainTtl * 100 / (totalTtl > 0 ? totalTtl : 1)}"/>
          <c:set var="ttlColorBar" value="${remainTtl > 300 ? '#2fb344' : remainTtl > 60 ? '#f59f00' : '#d63939'}"/>

          <div class="navbar-ttl-widget d-none d-lg-block">
            <div class="navbar-ttl-header">
              <span class="navbar-ttl-label">Token TTL</span>
              <span id="tokenTtl"
                    data-ttl="${remainTtl}"
                    data-bar="tokenTtlBar"
                    data-total="${totalTtl}"
                    class="navbar-ttl-badge <c:choose>
                      <c:when test='${remainTtl <= 60}'>ttl-danger</c:when>
                      <c:when test='${remainTtl <= 300}'>ttl-warning</c:when>
                    </c:choose>">
                <c:out value="${remainTtl}"/>s
              </span>
            </div>
            <div class="navbar-ttl-bar">
              <div id="tokenTtlBar"
                   class="navbar-ttl-bar-fill"
                   data-total="${totalTtl}"
                   style="width:${ttlPct}%; background:${ttlColorBar};"></div>
            </div>
          </div>
        </c:if>

        <%-- Right divider --%>
        <c:if test="${not empty sessionScope.vaultUsername}">
          <div class="navbar-right-divider d-none d-lg-block"></div>
        </c:if>

        <%-- User avatar + dropdown --%>
        <c:if test="${not empty sessionScope.vaultUsername}">
          <div class="nav-item dropdown" style="list-style:none;">
            <a href="#" class="nav-link d-flex align-items-center gap-2 p-0"
               data-bs-toggle="dropdown" aria-label="使用者選單"
               style="text-decoration:none;">
              <div class="navbar-user-avatar">
                <i class="bi bi-person-fill"></i>
              </div>
              <div class="d-none d-xl-block">
                <div class="navbar-user-name"><c:out value="${sessionScope.vaultUsername}"/></div>
                <div class="navbar-user-role">Vault 使用者</div>
              </div>
            </a>
            <div class="dropdown-menu dropdown-menu-end shadow-sm">
              <div class="dropdown-header small text-muted">
                <i class="bi bi-shield-check me-1"></i>已驗證身份
              </div>
              <div class="dropdown-divider m-0"></div>
              <form method="post" action="${pageContext.request.contextPath}/logout">
                <button type="submit" class="dropdown-item text-danger"
                        onclick="return confirm('確定要登出？')"
                        style="height:auto !important;">
                  <i class="bi bi-box-arrow-right me-2"></i>登出
                </button>
              </form>
            </div>
          </div>
        </c:if>

      </div><%-- /right side --%>
    </div><%-- /collapse --%>
  </div>
</header>

<div class="page-wrapper">
