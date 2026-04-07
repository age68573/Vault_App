<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="資料瀏覽器 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="data" scope="request"/>
<%@ include file="_header.jsp" %>

<div class="container-xl py-4">

  <div class="page-header d-print-none mb-4">
    <div class="row align-items-center">
      <div class="col">
        <h2 class="page-title">
          <i class="bi bi-database me-2 text-success"></i>MongoDB 資料瀏覽器
        </h2>
      </div>
    </div>
  </div>

  <%-- 無憑證警告 --%>
  <c:if test="${noCred}">
    <div class="alert alert-warning mb-4">
      <i class="bi bi-exclamation-triangle-fill me-1"></i>
      尚未申請動態憑證，或憑證已過期。請先
      <a href="${pageContext.request.contextPath}/creds" class="alert-link">申請動態憑證</a>
      後再使用資料瀏覽器。
    </div>
  </c:if>

  <%-- DB 錯誤 --%>
  <c:if test="${not empty dbError}">
    <div class="alert alert-danger mb-4">
      <i class="bi bi-exclamation-triangle-fill me-1"></i><c:out value="${dbError}"/>
    </div>
  </c:if>

  <%-- 操作結果訊息 --%>
  <c:if test="${not empty param.msg}">
    <div class="alert alert-success alert-dismissible fade show mb-4">
      <i class="bi bi-check-circle-fill me-1"></i><c:out value="${param.msg}"/>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>
  <c:if test="${not empty param.error}">
    <div class="alert alert-danger alert-dismissible fade show mb-4">
      <i class="bi bi-exclamation-triangle-fill me-1"></i><c:out value="${param.error}"/>
      <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
  </c:if>

  <c:if test="${not noCred and not empty currentCred}">
    <%-- 憑證資訊提示 --%>
    <div class="alert alert-info py-2 small mb-3">
      <i class="bi bi-key-fill me-1"></i>
      目前使用憑證：<strong><c:out value="${currentCred.username}"/></strong>
      &nbsp;|&nbsp;剩餘 TTL：
      <span class="badge bg-info text-dark"
            data-ttl="${currentCred.remainingTtlSeconds}">
        <c:out value="${currentCred.remainingTtlSeconds}"/>秒
      </span>
    </div>

    <div class="row g-3">

      <%-- 左側：Collection 清單 --%>
      <div class="col-md-3 col-lg-2">
        <div class="card mb-3">
          <div class="card-header bg-success-lt">
            <h4 class="card-title mb-0 small fw-semibold text-success">
              <i class="bi bi-collection me-1"></i>Collections
            </h4>
          </div>
          <div class="list-group list-group-flush">
            <c:choose>
              <c:when test="${empty collections}">
                <span class="list-group-item text-muted small">（無 Collection）</span>
              </c:when>
              <c:otherwise>
                <c:forEach var="coll" items="${collections}">
                  <a href="${pageContext.request.contextPath}/data?collection=${coll}"
                     class="list-group-item list-group-item-action small py-2
                            <c:if test='${coll == selectedCollection}'>active</c:if>">
                    <i class="bi bi-table me-1"></i><c:out value="${coll}"/>
                  </a>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </div>
        </div>

        <%-- 指定 Collection --%>
        <div class="card">
          <div class="card-header small fw-semibold">
            <i class="bi bi-plus-square me-1"></i>指定 Collection
          </div>
          <div class="card-body p-2">
            <form method="get" action="${pageContext.request.contextPath}/data">
              <div class="input-group input-group-sm">
                <input type="text" class="form-control form-control-sm"
                       name="collection"
                       placeholder="輸入名稱..."
                       value="<c:out value='${selectedCollection}'/>">
                <button type="submit" class="btn btn-sm btn-outline-secondary">
                  <i class="bi bi-search"></i>
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <%-- 右側：主要內容區 --%>
      <div class="col-md-9 col-lg-10">

        <c:choose>
          <c:when test="${not empty selectedCollection}">

            <%-- 查詢列 --%>
            <div class="card mb-3">
              <div class="card-header" style="background:#1a1a2e; color:#fff;">
                <h4 class="card-title mb-0 small">
                  <i class="bi bi-search me-2"></i>
                  查詢：<span class="font-monospace"><c:out value="${selectedCollection}"/></span>
                  <span class="badge bg-secondary ms-2">
                    <c:out value="${documentCount}"/>筆結果
                  </span>
                </h4>
              </div>
              <div class="card-body pb-2">
                <form method="get" action="${pageContext.request.contextPath}/data"
                      class="row g-2 align-items-end">
                  <input type="hidden" name="collection" value="${selectedCollection}">
                  <div class="col-md-7">
                    <label class="form-label small fw-semibold mb-1">
                      篩選條件（MongoDB JSON）
                    </label>
                    <input type="text" class="form-control form-control-sm font-monospace"
                           name="filter"
                           placeholder='{"field": "value"}  — 留空代表查全部'
                           value="<c:out value='${filterJson}'/>">
                  </div>
                  <div class="col-md-2">
                    <label class="form-label small fw-semibold mb-1">筆數限制</label>
                    <input type="number" class="form-control form-control-sm"
                           name="limit" value="${limit}" min="1" max="100">
                  </div>
                  <div class="col-md-3">
                    <button type="submit" class="btn btn-success btn-sm w-100">
                      <i class="bi bi-search me-1"></i>查詢
                    </button>
                  </div>
                </form>
              </div>
            </div>

            <%-- 查詢結果 --%>
            <c:if test="${not empty documents}">
              <div class="card mb-3">
                <div class="card-body p-0">
                  <div class="table-responsive">
                    <table class="table table-sm table-hover table-vcenter mb-0">
                      <thead>
                        <tr>
                          <th style="width:40px">#</th>
                          <th>文件內容（JSON）</th>
                          <th class="text-center" style="width:60px">操作</th>
                        </tr>
                      </thead>
                      <tbody>
                        <c:forEach var="doc" items="${documents}" varStatus="status">
                          <tr>
                            <td class="text-muted small"><c:out value="${status.index + 1}"/></td>
                            <td class="small font-monospace">
                              <span class="text-break" style="max-width:600px; display:block;">
                                <c:out value="${doc}"/>
                              </span>
                            </td>
                            <td class="text-center">
                              <form method="post"
                                    action="${pageContext.request.contextPath}/data"
                                    onsubmit="return confirm('確定要刪除這筆文件？此操作無法復原。')">
                                <input type="hidden" name="action"     value="delete">
                                <input type="hidden" name="collection" value="${selectedCollection}">
                                <input type="hidden" name="filterJson"
                                       value='<c:out value="${doc}"/>'
                                       class="delete-filter-input">
                                <button type="submit"
                                        class="btn btn-sm btn-outline-danger">
                                  <i class="bi bi-trash3"></i>
                                </button>
                              </form>
                            </td>
                          </tr>
                        </c:forEach>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </c:if>

            <c:if test="${empty documents and not empty selectedCollection}">
              <div class="alert alert-secondary small mb-3">
                <i class="bi bi-inbox me-1"></i>此 Collection 沒有符合條件的文件
              </div>
            </c:if>

            <%-- 新增文件 --%>
            <div class="accordion mb-3" id="insertAccordion">
              <div class="accordion-item">
                <h2 class="accordion-header">
                  <button class="accordion-button collapsed fw-semibold"
                          type="button" data-bs-toggle="collapse"
                          data-bs-target="#collapseInsert">
                    <i class="bi bi-plus-circle me-2 text-success"></i>新增文件
                  </button>
                </h2>
                <div id="collapseInsert" class="accordion-collapse collapse">
                  <div class="accordion-body">
                    <form method="post" action="${pageContext.request.contextPath}/data">
                      <input type="hidden" name="action"     value="insert">
                      <input type="hidden" name="collection" value="${selectedCollection}">
                      <div class="mb-3">
                        <label class="form-label fw-semibold">
                          文件內容（JSON 格式）
                        </label>
                        <textarea class="form-control font-monospace"
                                  name="documentJson" rows="5"
                                  placeholder='{"name": "範例", "value": 123}'
                                  required></textarea>
                        <div class="form-text">
                          無需指定 _id，MongoDB 將自動產生
                        </div>
                      </div>
                      <button type="submit" class="btn btn-success">
                        <i class="bi bi-plus-circle me-1"></i>新增文件
                      </button>
                    </form>
                  </div>
                </div>
              </div>
            </div>

          </c:when>
          <c:otherwise>
            <div class="card">
              <div class="card-body text-center py-5 text-muted">
                <i class="bi bi-arrow-left-circle" style="font-size:2.5rem;"></i>
                <p class="mt-2">請從左側選擇或輸入 Collection 名稱以開始操作</p>
              </div>
            </div>
          </c:otherwise>
        </c:choose>

      </div><%-- /右側 --%>
    </div><%-- /row --%>

  </c:if><%-- /not noCred --%>
</div>

<%@ include file="_footer.jsp" %>
<script>
document.querySelectorAll('.delete-filter-input').forEach(input => {
  try {
    const doc = JSON.parse(input.value);
    if (doc._id) {
      input.value = JSON.stringify({ _id: doc._id });
    }
  } catch (e) { /* 保留原值 */ }
});
</script>
