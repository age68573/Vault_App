<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%--
  共用頁尾片段
  使用方式：<%@ include file="_footer.jsp" %>
--%>
</div><%-- /page-wrapper --%>

<footer class="footer footer-transparent d-print-none mt-auto py-3">
  <div class="container-fluid">
    <div class="row text-center align-items-center">
      <div class="col-12 col-lg-auto text-muted small">
        <i class="bi bi-shield-lock me-1"></i>
        HashiCorp Vault 動態憑證展示 &mdash; JBoss EAP 8 + MongoDB
      </div>
    </div>
  </div>
</footer>

</div><%-- /wrapper --%>

<script src="${pageContext.request.contextPath}/static/js/tabler.min.js"></script>
<script src="${pageContext.request.contextPath}/static/js/app.js"></script>
</body>
</html>
