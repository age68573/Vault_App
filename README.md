# Vault MongoDB 動態憑證展示應用程式

## 目錄

- [專案概述](#專案概述)
- [系統架構](#系統架構)
- [技術堆疊](#技術堆疊)
- [專案結構](#專案結構)
- [核心功能說明](#核心功能說明)
- [設定說明](#設定說明)
- [Vault 前置設定](#vault-前置設定)
- [MongoDB 前置設定](#mongodb-前置設定)
- [建置與部署](#建置與部署)
- [頁面說明](#頁面說明)
- [API 呼叫對照表](#api-呼叫對照表)
- [已知注意事項](#已知注意事項)

---

## 專案概述

本應用程式是一個展示系統，核心目的是示範如何透過 **HashiCorp Vault Database Secrets Engine** 動態產生 MongoDB 短期憑證，並使用該憑證對 MongoDB 進行 CRUD 操作。

**核心流程：**

```
使用者登入 Vault
    → Vault 核發 Token
        → 應用程式持 Token 向 Vault 申請 MongoDB 動態憑證（帳號 + 密碼）
            → 使用動態憑證連線 MongoDB 執行資料操作
                → Lease 到期後動態憑證自動失效
```

每次申請的 MongoDB 帳號密碼均不同，且具有限定的存活時間（TTL），到期後 Vault 會自動從 MongoDB 中刪除該帳號。

---

## 系統架構

```
┌─────────────────────────────────────────────────────┐
│                   使用者瀏覽器                        │
│            Bootstrap 5 + JSP (繁體中文)               │
└────────────────────┬────────────────────────────────┘
                     │ HTTP
┌────────────────────▼────────────────────────────────┐
│              JBoss EAP 8 (Java 11)                   │
│                                                       │
│  AuthFilter ──→ Servlet ──→ VaultService             │
│                    │            │                     │
│                    │            ▼                     │
│                    │      VaultHttpClient             │
│                    │       (Java 11 HttpClient)       │
│                    │                                  │
│                    ├──→ MongoService                  │
│                    │    (ConcurrentHashMap            │
│                    │     leaseId→MongoClient)         │
│                    │                                  │
│                    └──→ AuditLogService               │
│                         (記憶體環狀緩衝區)              │
└──────────┬──────────────────────┬───────────────────┘
           │ HTTPS                │ TCP
┌──────────▼──────────┐  ┌───────▼───────────────────┐
│   HashiCorp Vault   │  │        MongoDB             │
│  Database Secrets   │  │  (動態帳號由 Vault 管理)    │
│      Engine         │  │                            │
└─────────────────────┘  └────────────────────────────┘
```

---

## 技術堆疊

| 類別 | 技術 | 版本 |
|------|------|------|
| 應用程式伺服器 | JBoss EAP | 8.x |
| Java 版本 | OpenJDK | 11 |
| Jakarta EE | Web API | 10.0.0 |
| CDI 容器 | Weld（JBoss 內建） | — |
| 前端框架 | Bootstrap | 5.3.2 |
| 圖示庫 | Bootstrap Icons | 1.11.3 |
| 視圖技術 | JSP + JSTL | Jakarta JSTL 3.0 |
| MongoDB Driver | mongodb-driver-sync | 4.11.1 |
| JSON 解析 | Jackson Databind | 2.16.1 |
| 日誌框架 | Logback Classic | 1.4.14 |
| HTTP Client | Java 11 內建 HttpClient | — |
| 打包格式 | WAR | — |

**注意：** MongoDB Driver、Jackson、Logback 均打包進 WAR，不依賴 JBoss 提供，避免類別衝突。

---

## 專案結構

```
JavaApp/
├── pom.xml
├── APPLICATION.md                          ← 本文件
└── src/
    ├── main/
    │   ├── java/com/jeremylab/vaultdemo/
    │   │   ├── config/
    │   │   │   └── AppConfig.java          ← 應用程式設定（讀取系統屬性/環境變數）
    │   │   ├── model/
    │   │   │   ├── VaultToken.java         ← Vault Token 模型
    │   │   │   ├── DynamicCredential.java  ← 動態憑證模型（含 TTL 計算）
    │   │   │   ├── LeaseInfo.java          ← Lease 資訊模型
    │   │   │   └── AuditEntry.java         ← 稽核記錄模型
    │   │   ├── service/
    │   │   │   ├── VaultException.java     ← Vault 基礎例外（含 HTTP 狀態碼）
    │   │   │   ├── VaultAuthException.java ← HTTP 403 專用例外
    │   │   │   ├── VaultService.java       ← Vault REST API 封裝（@ApplicationScoped）
    │   │   │   ├── MongoService.java       ← MongoDB 連線管理（@ApplicationScoped）
    │   │   │   └── AuditLogService.java    ← 稽核日誌服務（@ApplicationScoped）
    │   │   ├── util/
    │   │   │   ├── JsonUtil.java           ← Jackson 工具類別
    │   │   │   └── VaultHttpClient.java    ← HTTP 客戶端（支援 TLS 略過驗證）
    │   │   ├── filter/
    │   │   │   └── AuthFilter.java         ← 身份驗證過濾器（@WebFilter）
    │   │   └── servlet/
    │   │       ├── LoginServlet.java        ← GET/POST /login
    │   │       ├── LogoutServlet.java       ← POST /logout
    │   │       ├── DashboardServlet.java    ← GET /dashboard
    │   │       ├── DynamicCredServlet.java  ← GET/POST /creds
    │   │       ├── LeaseManagerServlet.java ← GET/POST /leases
    │   │       ├── DataExplorerServlet.java ← GET/POST /data
    │   │       └── AuditLogServlet.java     ← GET /audit
    │   ├── resources/
    │   │   └── logback.xml                 ← 日誌設定
    │   └── webapp/
    │       ├── index.jsp                   ← 重導至 /login
    │       ├── WEB-INF/
    │       │   ├── web.xml                 ← Jakarta EE 10 Web 設定
    │       │   ├── beans.xml               ← CDI 啟用設定（必要）
    │       │   ├── jboss-web.xml           ← Context root /vaultdemo
    │       │   ├── jboss-deployment-structure.xml ← 排除 JBoss 內建 Jackson/SLF4J
    │       │   └── views/
    │       │       ├── _header.jsp         ← 共用頁首（Bootstrap Navbar）
    │       │       ├── _footer.jsp         ← 共用頁尾（Bootstrap JS）
    │       │       ├── login.jsp
    │       │       ├── dashboard.jsp
    │       │       ├── dynamic-creds.jsp
    │       │       ├── lease-manager.jsp
    │       │       ├── data-explorer.jsp
    │       │       ├── audit-log.jsp
    │       │       └── error/
    │       │           ├── 404.jsp
    │       │           └── 500.jsp
    │       └── static/
    │           ├── css/app.css             ← TTL 倒數動畫、版面樣式
    │           └── js/app.js               ← TTL 倒數計時器（JavaScript）
    └── test/
        └── java/                           ← 單元測試（JUnit 5 + Mockito）
```

---

## 核心功能說明

### 1. Vault 認證（Username/Password）

- 呼叫 `POST /v1/auth/userpass/login/{username}`
- 成功後取得 `client_token`，儲存在 HTTP Session
- Session 中的 `VaultToken` 包含 `remainingTtlSeconds()` 方法，前端每秒倒數顯示
- Token 過期時前端自動跳轉至登入頁

### 2. 動態憑證申請

- 呼叫 `GET /v1/database/creds/{role}`（role 預設為 `mongo-role`）
- Vault 在 MongoDB 中自動建立一個臨時帳號（格式：`v-userpass-{user}-xxxxxxxx`）
- 回傳 `username`、`password`、`lease_id`、`lease_duration`
- 每次申請都產生不同的帳號密碼組合

### 3. Lease 生命週期管理

| 操作 | Vault API | 說明 |
|------|-----------|------|
| 列出 Lease | `LIST /v1/sys/leases/lookup/database/creds/{role}` | 取得該 role 下所有活躍 Lease ID |
| 查詢 Lease | `PUT /v1/sys/leases/lookup` | 取得 TTL、expire_time 等資訊 |
| 續期 Lease | `PUT /v1/sys/leases/renew` | 延長憑證存活時間（預設 +3600 秒）|
| 撤銷 Lease | `PUT /v1/sys/leases/revoke` | 立即使憑證失效並從 MongoDB 刪除帳號 |

**Lease 查詢機制：** 優先使用 `LIST /v1/sys/leases/lookup/{prefix}` 向 Vault 直接查詢（需要 Policy 具備 `sudo + list` capability），若權限不足則自動退回使用 Session 中的 `knownLeaseIds` 清單。

**重要限制：** Vault 的密碼只在**第一次申請時**回傳，之後任何 API 都無法再取得。因此登出後重新登入，即使 Lease 仍有效，也無法還原密碼，需重新申請動態憑證。

### 4. MongoDB 連線管理

- `MongoService` 使用 `ConcurrentHashMap<leaseId, MongoClient>` 管理連線池
- 連線字串格式：`mongodb://{username}:{password}@{host}:{port}/{db}?authSource=admin`
- 憑證撤銷時同步關閉對應 `MongoClient`
- **不使用 JNDI DataSource**，因動態憑證每次帳密不同

### 5. 稽核日誌

- `AuditLogService` 以記憶體環狀緩衝區儲存最多 500 筆記錄（最新在前）
- 記錄所有操作：登入、申請憑證、Lease 操作、MongoDB CRUD
- **這是應用程式層級的日誌**，非 Vault 本身的 Audit Device

---

## 設定說明

所有設定透過 `AppConfig.java` 讀取，優先順序：**JVM 系統屬性 > 環境變數 > 預設值**

| 設定名稱 | JVM 系統屬性 | 環境變數 | 預設值 | 說明 |
|---------|------------|---------|-------|------|
| Vault 位址 | `vault.addr` | `VAULT_ADDR` | `http://127.0.0.1:8200` | Vault 伺服器 URL |
| Vault DB Role | `vault.db.role` | `VAULT_DB_ROLE` | `mongo-role` | Database Secrets Engine 角色名稱 |
| Vault 命名空間 | `vault.namespace` | `VAULT_NAMESPACE` | `""` | Enterprise 版命名空間，OSS 留空 |
| TLS 略過驗證 | `vault.skip.verify` | `VAULT_SKIP_VERIFY` | `false` | 開發環境使用，略過憑證驗證 |
| MongoDB 主機 | `mongo.host` | `MONGO_HOST` | `127.0.0.1` | MongoDB 伺服器位址 |
| MongoDB 連接埠 | `mongo.port` | `MONGO_PORT` | `27017` | MongoDB 連接埠 |
| MongoDB 資料庫 | `mongo.db.name` | `MONGO_DB_NAME` | `vaultdemo` | 操作的資料庫名稱 |
| HTTP 逾時 | `http.timeout` | `HTTP_TIMEOUT_SECONDS` | `10` | Vault API 請求逾時秒數 |

### 方式一：直接修改 AppConfig.java 預設值（快速測試）

```java
VAULT_ADDR = get("vault.addr", "VAULT_ADDR", "https://10.107.85.84:8200");
MONGO_HOST = get("mongo.host", "MONGO_HOST", "10.107.85.88");
```

### 方式二：透過 JBoss standalone.xml（推薦正式環境）

```xml
<system-properties>
    <property name="vault.addr"        value="https://10.107.85.84:8200"/>
    <property name="vault.db.role"     value="mongo-role"/>
    <property name="vault.namespace"   value="root"/>
    <property name="vault.skip.verify" value="true"/>
    <property name="mongo.host"        value="10.107.85.88"/>
    <property name="mongo.db.name"     value="vaultdemo"/>
</system-properties>
```

---

## Vault 前置設定

### 1. 啟用 Userpass 認證

```bash
vault auth enable userpass
```

### 2. 建立使用者

```bash
vault write auth/userpass/users/jeremy \
    password="your-password" \
    policies="mongo-demo-policy"
```

### 3. 建立 Policy

```bash
vault policy write mongo-demo-policy - <<EOF
path "database/creds/mongo-role" {
  capabilities = ["read"]
}
path "sys/leases/lookup" {
  capabilities = ["update"]
}
path "sys/leases/renew" {
  capabilities = ["update"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
path "auth/token/revoke-self" {
  capabilities = ["update"]
}
EOF
```

### 4. 啟用 Database Secrets Engine

```bash
vault secrets enable database
```

### 5. 設定 MongoDB 連線（Vault → MongoDB）

```bash
vault write database/config/mongodb \
    plugin_name=mongodb-database-plugin \
    allowed_roles="mongo-role" \
    connection_url="mongodb://{{username}}:{{password}}@127.0.0.1:27017/admin" \
    username="vault-admin" \
    password="vault-admin-password"
```

### 6. 建立 MongoDB Role

```bash
vault write database/roles/mongo-role \
    db_name=mongodb \
    creation_statements='{"db":"admin","roles":[{"role":"readWrite","db":"vaultdemo"}]}' \
    default_ttl="1h" \
    max_ttl="24h"
```

### 7. 驗證設定

```bash
vault login -method=userpass username=jeremy
vault read database/creds/mongo-role
```

---

## MongoDB 前置設定

### 1. 啟用身份驗證（mongod.conf）

```yaml
security:
  authorization: enabled
```

### 2. 建立 Vault 管理帳號

```javascript
use admin
db.createUser({
  user: "vault-admin",
  pwd: "vault-admin-password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" }
  ]
})
```

> 此帳號供 Vault 用來動態建立/刪除應用程式帳號，需對應到 Vault 的 `database/config/mongodb` 設定。

### 3. 建立應用程式資料庫

```javascript
use vaultdemo
db.createCollection("demo")
```

> 或讓 MongoDB 在第一次寫入時自動建立，不需手動建立。

---

## 建置與部署

### 前置需求

- Java 11+
- Maven 3.6+
- JBoss EAP 8.x

### 建置步驟

```bash
cd c:\Users\Administrator\Desktop\Jeremy-Lab\JavaApp

# 編譯並打包
mvn clean package

# 產生檔案：target/vault-mongo-demo.war
```

### 部署步驟

```bash
# 複製 WAR 至 JBoss 部署目錄
cp target/vault-mongo-demo.war $JBOSS_HOME/standalone/deployments/

# JBoss 會自動偵測並部署（hot deploy）
# 確認出現 vault-mongo-demo.war.deployed 檔案表示部署成功
```

### 存取網址

```
http://{jboss-host}:8080/vaultdemo
```

---

## 頁面說明

| 路徑 | 頁面 | 功能 |
|------|------|------|
| `/vaultdemo` | 首頁 | 自動重導至 `/login` |
| `/vaultdemo/login` | 登入 | Vault Userpass 登入 |
| `/vaultdemo/dashboard` | 儀表板 | Token 狀態、Lease 數量、MongoDB 連線狀態 |
| `/vaultdemo/creds` | 動態憑證 | 申請新的 MongoDB 動態憑證、查看目前憑證 |
| `/vaultdemo/leases` | Lease 管理 | 查詢、續期、撤銷所有活躍 Lease |
| `/vaultdemo/data` | 資料瀏覽器 | 瀏覽 Collection、查詢/新增/刪除文件 |
| `/vaultdemo/audit` | 稽核日誌 | 查看應用程式操作記錄，可依操作類型過濾 |

---

## API 呼叫對照表

| 應用程式操作 | Vault API |
|------------|-----------|
| 使用者登入 | `POST /v1/auth/userpass/login/{username}` |
| 查詢 Token 資訊 | `GET /v1/auth/token/lookup-self` |
| 登出（清除 Session） | — （不呼叫 revoke-self，保留 Lease） |
| 申請動態憑證 | `GET /v1/database/creds/{role}` |
| 列出所有 Lease | `LIST /v1/sys/leases/lookup/database/creds/{role}` |
| 查詢 Lease 狀態 | `PUT /v1/sys/leases/lookup` |
| 續期 Lease | `PUT /v1/sys/leases/renew` |
| 撤銷 Lease | `PUT /v1/sys/leases/revoke` |

---

## 已知注意事項

### TLS 憑證驗證
若 Vault 使用 HTTPS 且憑證為自簽憑證，需設定 `vault.skip.verify=true`。**僅限開發環境使用，正式環境請匯入正確的 CA 憑證。**

### CDI 啟用
`WEB-INF/beans.xml` 是啟用 CDI 的必要檔案，缺少此檔案會導致 `@Inject` 失敗，所有頁面回傳 500。

### Jackson/SLF4J 類別衝突
`jboss-deployment-structure.xml` 排除了 JBoss 內建的 Jackson 與 SLF4J 模組，確保應用程式使用打包進 WAR 的版本。

### Vault LIST Leases 權限
`LIST /v1/sys/leases/lookup/{prefix}` 需要 Policy 具備 `sudo + list` capability。已在 Policy 中加入對應路徑，若未設定則自動退回 Session 清單查詢。

### 登出不撤銷 Token
應用程式登出時只清除 Session，不呼叫 `revoke-self`。原因是 Token 撤銷會連帶撤銷其底下所有子 Lease（動態憑證），導致重新登入後 Lease 消失。Lease 將依 TTL 自然到期，或由使用者在 Lease 管理頁面手動撤銷。

### 動態憑證密碼無法還原
Vault 只在申請動態憑證的當下回傳密碼，之後任何 API 均無法再取得。登出後重新登入需重新申請憑證才能使用資料瀏覽器。

### Session 安全
登入成功後會呼叫 `session.invalidate()` 並建立新 Session，防止 Session Fixation 攻擊。Session Cookie 設定為 HttpOnly。
