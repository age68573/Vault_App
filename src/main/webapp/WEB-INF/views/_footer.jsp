<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
  共用頁尾片段
  使用方式：<%@ include file="_footer.jsp" %>
--%>
<footer class="footer mt-auto py-3 bg-light border-top">
  <div class="container-fluid text-center text-muted small">
    <i class="bi bi-shield-lock me-1"></i>
    HashiCorp Vault 動態憑證展示應用程式 &mdash; JBoss EAP 8 + MongoDB
  </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="${pageContext.request.contextPath}/static/js/app.js"></script>
</body>
</html>
