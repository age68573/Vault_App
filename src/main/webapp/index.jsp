<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%-- 根頁面：重導至登入頁面 --%>
<% response.sendRedirect(request.getContextPath() + "/login"); %>
