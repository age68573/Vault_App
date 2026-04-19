# UI 風格指南 — Vault MongoDB 動態憑證展示

基礎框架：[Tabler](https://tabler.io/) + Bootstrap 5 + Bootstrap Icons  
字體：Inter（正文）、JetBrains Mono（程式碼）  
JSP 標籤庫：`jakarta.tags.core`（JSTL）

---

## 目錄

1. [Color Tokens](#1-color-tokens)
2. [Typography](#2-typography)
3. [Layout 骨架](#3-layout-骨架)
4. [Navbar](#4-navbar)
5. [Card](#5-card)
6. [Buttons](#6-buttons)
7. [Badge](#7-badge)
8. [Progress Bar / TTL 倒數條](#8-progress-bar--ttl-倒數條)
9. [Alert](#9-alert)
10. [Table](#10-table)
11. [Login 頁面 Tabs](#11-login-頁面-tabs)
12. [Empty State](#12-empty-state)
13. [JS：TTL 倒數計時器](#13-jsttl-倒數計時器)

---

## 1. Color Tokens

定義在 `app.css` 的 `:root`，使用 CSS 變數全域統一色票。

| 變數 | 色碼 | 用途 |
|---|---|---|
| `--color-vault` | `#f59f00` | 品牌色（Vault 金）|
| `--color-primary` | `#0054a6` | 主要行動 |
| `--color-success` | `#2fb344` | 正常 / TTL 充足（>300s）|
| `--color-warning` | `#f59f00` | 警戒 / TTL 偏低（61-300s）|
| `--color-danger` | `#d63939` | 危險 / TTL 即將到期（≤60s）|
| `--color-info` | `#4299e1` | 資訊 / 憑證 TTL |
| `--color-secondary` | `#6c757d` | 次要文字 |
| `--color-page-bg` | `#f1f5f9` | 頁面背景 |
| `--color-surface` | `#ffffff` | 卡片 / 彈出層表面 |
| `--color-border` | `#e2e6ec` | 所有邊框 |
| `--color-body` | `#1d273b` | 主文字 |
| `--color-muted` | `#6c757d` | 輔助文字 |

---

## 2. Typography

```html
<!-- 正文（Inter） -->
<style>
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
</style>

<!-- 等寬（Lease ID、帳號密碼）-->
<span class="font-monospace small text-muted">database/creds/mongo...</span>

<!-- JSON 區塊 -->
<code class="json-block">{ "username": "v-app-abc123" }</code>
```

---

## 3. Layout 骨架

每個頁面固定結構：`_header.jsp` → 頁面內容 → `_footer.jsp`

```jsp
<%@ include file="_header.jsp" %>

<!-- 頁面標題列 -->
<div class="page-header d-print-none">
  <div class="container-xl">
    <div class="row g-2 align-items-center">
      <div class="col">
        <h2 class="page-title">頁面標題</h2>
        <div class="text-muted mt-1 small">副標題說明</div>
      </div>
      <div class="col-auto ms-auto">
        <!-- 右側操作按鈕 -->
        <a href="#" class="btn btn-outline-secondary btn-sm">
          <i class="bi bi-arrow-clockwise me-1"></i>重新整理
        </a>
      </div>
    </div>
  </div>
</div>

<!-- 頁面主體 -->
<div class="page-body">
  <div class="container-xl">
    <!-- 內容 -->
  </div>
</div>

<%@ include file="_footer.jsp" %>
```

`_header.jsp` 需要兩個 request 屬性：

```jsp
<c:set var="pageTitle"   value="頁面標題 — Vault MongoDB 展示" scope="request"/>
<c:set var="currentPage" value="dashboard"  scope="request"/>
<%-- currentPage 可選值：dashboard / creds / leases / data / audit --%>
```

---

## 4. Navbar

Navbar 由 `_header.jsp` 自動渲染，右側的 **Token TTL widget** 讀取 Session：

```java
// Servlet 需在 Session 中放入：
session.setAttribute("vaultToken",    token);       // VaultToken 物件
session.setAttribute("vaultUsername", username);    // 顯示名稱
```

TTL 分三段顏色（CSS class 自動套用）：

| 剩餘時間 | CSS Class | 顏色 |
|---|---|---|
| > 300s | —（預設綠）| `#2fb344` |
| 61–300s | `ttl-warning` | `#f59f00` |
| ≤ 60s | `ttl-danger` + blink | `#d63939` |

---

## 5. Card

```html
<!-- 標準卡片 -->
<div class="card">
  <div class="card-header">
    <h3 class="card-title">
      <!-- 選用：icon chip -->
      <span class="avatar avatar-sm bg-primary-lt text-primary me-2">
        <i class="bi bi-shield-check"></i>
      </span>
      卡片標題
    </h3>
    <div class="card-options">
      <!-- 右側副操作 -->
      <a href="#" class="btn btn-sm btn-ghost-secondary">管理</a>
    </div>
  </div>
  <div class="card-body">
    <!-- 內容 -->
  </div>
  <div class="card-footer">
    <!-- 底部操作 -->
  </div>
</div>

<!-- 統計卡片列（3 欄） -->
<div class="row row-deck row-cards mb-4">
  <div class="col-md-4">
    <div class="card">...</div>
  </div>
</div>

<!-- 快速功能卡（hover 浮起） -->
<a href="#" class="card card-link card-link-pop text-center p-3 border">
  <div class="avatar avatar-lg bg-warning-lt text-warning mx-auto mb-2">
    <i class="bi bi-key-fill fs-4"></i>
  </div>
  <div class="small fw-semibold">功能名稱</div>
</a>
```

Icon chip 顏色配對：

| 語意 | bg class | text class |
|---|---|---|
| 主要 | `bg-primary-lt` | `text-primary` |
| 成功 | `bg-success-lt` | `text-success` |
| 警告 | `bg-warning-lt` | `text-warning` |
| 資訊 | `bg-info-lt` | `text-info` |
| 次要 | `bg-secondary-lt` | `text-secondary` |

---

## 6. Buttons

```html
<!-- 主要行動 -->
<button class="btn btn-primary w-100">
  <i class="bi bi-shield-check me-1"></i>登入 Vault
</button>

<!-- 小按鈕（高度 28px）-->
<a href="#" class="btn btn-outline-secondary btn-sm">
  <i class="bi bi-arrow-clockwise me-1"></i>重新整理
</a>

<!-- 操作組（並排）-->
<div class="d-flex gap-2">
  <button class="btn btn-sm btn-outline-primary">
    <i class="bi bi-arrow-repeat me-1"></i>續期
  </button>
  <button class="btn btn-sm btn-outline-danger">
    <i class="bi bi-trash3 me-1"></i>撤銷
  </button>
</div>
```

---

## 7. Badge

```html
<!-- 語意 badge（Tabler -lt 風格，柔和背景）-->
<span class="badge bg-success-lt text-success">是</span>
<span class="badge bg-warning-lt text-warning">警戒</span>
<span class="badge bg-danger-lt  text-danger">危險</span>
<span class="badge bg-primary-lt text-primary">policy-name</span>
<span class="badge bg-secondary-lt text-secondary">否</span>

<!-- 數量 badge（卡片標題旁）-->
<span class="badge bg-primary-lt text-primary ms-2">${count}</span>

<!-- Bootstrap 實心（用於 progress 旁的 TTL 倒數，JS 會切換 class）-->
<span class="badge bg-success" data-ttl="${ttl}" data-bar="barId">
  <c:out value="${ttl}"/>s
</span>
```

---

## 8. Progress Bar / TTL 倒數條

### HTML 結構

```html
<!-- badge + 進度條固定搭配 -->
<span class="badge bg-success mb-1"
      id="myTtlBadge"
      data-ttl="${remainingSeconds}"
      data-bar="myBar">
  <c:out value="${remainingSeconds}"/>s
</span>

<div class="progress progress-sm">
  <div id="myBar"
       class="progress-bar bg-success"
       role="progressbar"
       data-total="${originalDurationSeconds}"
       style="width:${remainingSeconds * 100 / originalDurationSeconds}%">
  </div>
</div>
```

**重要**：`data-total` 必須是**原始總時長**（不是剩餘秒數），`style="width:…%"` 是伺服端計算的初始值。

### 進度條顏色對應語意

| 剩餘 | badge class | bar class | track class |
|---|---|---|---|
| >300s | `bg-success` | `bg-success` | `progress-track-success`（可選）|
| 61-300s | `bg-warning text-dark` | `bg-warning` | — |
| ≤60s | `bg-danger` | `bg-danger` | — |
| 憑證 TTL | `bg-info-lt text-info` | `bg-info` | `progress-track-info`（可選）|

### Navbar 版本（小型 widget）

```html
<div class="navbar-ttl-widget d-none d-lg-block">
  <div class="navbar-ttl-header">
    <span class="navbar-ttl-label">Token TTL</span>
    <span id="tokenTtl"
          class="navbar-ttl-badge"
          data-ttl="${remainTtl}"
          data-bar="tokenTtlBar">
      <c:out value="${remainTtl}"/>s
    </span>
  </div>
  <div class="navbar-ttl-bar">
    <div id="tokenTtlBar"
         class="navbar-ttl-bar-fill"
         data-total="${totalTtl}"
         style="width:${ttlPct}%; background:#2fb344;">
    </div>
  </div>
</div>
```

---

## 9. Alert

```html
<!-- 成功（含關閉）-->
<div class="alert alert-success alert-dismissible mb-4">
  <i class="bi bi-check-circle-fill me-2"></i>操作成功訊息
  <a class="btn-close" data-bs-dismiss="alert"></a>
</div>

<!-- 錯誤 -->
<div class="alert alert-danger alert-dismissible mb-4">
  <div class="d-flex">
    <div><i class="bi bi-exclamation-triangle-fill me-2"></i></div>
    <div><c:out value="${error}"/></div>
  </div>
  <a class="btn-close" data-bs-dismiss="alert"></a>
</div>

<!-- 資訊（說明區塊）-->
<div class="alert alert-info mb-3">
  <div class="d-flex">
    <div><i class="bi bi-info-circle me-2"></i></div>
    <div class="small">說明文字</div>
  </div>
</div>

<!-- JSP 條件渲染 -->
<c:if test="${not empty error}">
  <div class="alert alert-danger ...">
    <c:out value="${error}"/>
  </div>
</c:if>
```

---

## 10. Table

```html
<div class="table-responsive">
  <table class="table table-vcenter table-hover card-table">
    <thead>
      <tr>
        <th>欄位一</th>
        <th class="text-center" style="width:120px;">操作</th>
      </tr>
    </thead>
    <tbody>
      <c:forEach var="item" items="${items}" varStatus="vs">
        <tr>
          <!-- 等寬截斷，Tooltip 顯示完整內容 -->
          <td class="font-monospace small text-muted"
              title="${item.fullId}"
              data-bs-toggle="tooltip" data-bs-placement="top">
            <c:out value="${item.shortId}"/>
          </td>
          <td class="text-center">
            <!-- 操作按鈕 -->
          </td>
        </tr>
      </c:forEach>
    </tbody>
  </table>
</div>
```

> Tooltip 需在頁面底部初始化：
> ```js
> document.querySelectorAll('[data-bs-toggle="tooltip"]')
>   .forEach(el => new bootstrap.Tooltip(el));
> ```

---

## 11. Login 頁面 Tabs

```html
<!-- CSS class: login-auth-tabs / login-auth-tab / login-auth-tab.active -->
<div class="login-auth-tabs">
  <button class="login-auth-tab active" id="tab-a" type="button" onclick="selectAuth('a')">
    <i class="bi bi-person-lock me-1"></i>選項 A
  </button>
  <button class="login-auth-tab" id="tab-b" type="button" onclick="selectAuth('b')">
    <i class="bi bi-diagram-3 me-1"></i>選項 B
  </button>
</div>

<input type="hidden" id="authMethod" name="authMethod" value="a">

<script>
function selectAuth(method) {
  document.getElementById('authMethod').value = method;
  document.getElementById('tab-a').classList.toggle('active', method === 'a');
  document.getElementById('tab-b').classList.toggle('active', method === 'b');
}
</script>
```

---

## 12. Empty State

```html
<!-- 大型（整個 card-body）-->
<div class="empty">
  <div class="empty-icon">
    <i class="bi bi-inbox" style="font-size:2.5rem; color:var(--tblr-secondary);"></i>
  </div>
  <p class="empty-title">尚無資料</p>
  <p class="empty-subtitle text-muted">說明文字</p>
  <div class="empty-action">
    <a href="#" class="btn btn-primary btn-sm">
      <i class="bi bi-plus me-1"></i>新增
    </a>
  </div>
</div>

<!-- 小型（卡片內嵌）-->
<div class="empty empty-sm">
  <p class="empty-subtitle text-muted">無法取得資訊</p>
</div>
```

---

## 13. JS：TTL 倒數計時器

`app.js` 在 `DOMContentLoaded` 後自動掃描所有 `[data-ttl]` 元素並啟動計時器，不需手動呼叫。

### 觸發條件

| 屬性 | 說明 |
|---|---|
| `data-ttl="秒數"` | 放在 badge 元素上，初始剩餘秒數 |
| `data-bar="元素ID"` | 對應的進度條 `id` |
| `data-total="秒數"` | 放在**進度條元素**上，原始總時長 |

### 特殊 id（Token 過期自動跳轉）

`id="tokenTtl"` 或 `id="dashTtl"` — 這兩個 id 到期後會彈出提示並跳回 `/login`。

### `formatTtl()` 輸出格式

| 輸入 | 輸出 |
|---|---|
| ≤ 0 | `已過期` |
| < 60 | `45s` |
| 3661 | `1h 1m 1s` |
| 2481 | `41m 21s` |
