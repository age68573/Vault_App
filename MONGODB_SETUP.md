# MongoDB 前置設定指南

本文件說明部署展示應用程式前，需要在 MongoDB 完成的所有設定。

---

## 目錄

1. [前置確認](#前置確認)
2. [啟用身份驗證](#1-啟用身份驗證)
3. [建立 Vault 管理帳號](#2-建立-vault-管理帳號)
4. [建立應用程式資料庫](#3-建立應用程式資料庫)
5. [驗證設定](#4-驗證設定)
6. [動態帳號說明](#5-動態帳號說明)
7. [透過應用程式新增資料並用 mongosh 驗證](#6-透過應用程式新增資料並用-mongosh-驗證)

---

## 前置確認

- MongoDB 已安裝並啟動
- 可透過 `mongosh` 或 `mongo` 連線至 MongoDB

```bash
# 確認 MongoDB 狀態
systemctl status mongod

# 或查看 port 是否監聽
ss -tlnp | grep 27017
```

---

## 1. 啟用身份驗證

修改 `/etc/mongod.conf`，加入或確認以下設定：

```yaml
security:
  authorization: enabled

net:
  port: 27017
  bindIp: 0.0.0.0    # 允許遠端連線（依實際需求調整）
```

重啟 MongoDB：
```bash
systemctl restart mongod
```

> **注意：** 啟用 authorization 前，請先確保已建立管理帳號，否則啟用後將無法登入。
> 若尚未建立帳號，可在啟用 authorization 之前，先以 localhost exception 連入建立帳號。

---

## 2. 建立 Vault 管理帳號

此帳號供 Vault 連線 MongoDB，用來動態建立和刪除應用程式帳號。

### 在啟用 authorization 之前建立（使用 localhost exception）

```bash
mongosh
```

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

### 驗證管理帳號

```bash
mongosh -u vault-admin -p vault-admin-password --authenticationDatabase admin
```

| 欄位 | 說明 |
|------|------|
| `user` | 帳號名稱，需與 Vault `database/config/mongodb` 設定中的 `username` 一致 |
| `pwd` | 密碼，需與 Vault `database/config/mongodb` 設定中的 `password` 一致 |
| `userAdminAnyDatabase` | 允許 Vault 在任何資料庫建立和刪除帳號 |
| `readWriteAnyDatabase` | 允許 Vault 管理帳號本身讀寫資料（部分版本需要） |

---

## 3. 建立應用程式資料庫

應用程式預設使用 `vaultdemo` 資料庫（可透過 `mongo.db.name` 設定修改）。

```bash
mongosh -u vault-admin -p vault-admin-password --authenticationDatabase admin
```

```javascript
use vaultdemo
db.createCollection("demo")

// 新增一筆測試資料（可選）
db.demo.insertOne({
  name: "測試資料",
  description: "這是一筆測試文件",
  createdAt: new Date()
})
```

> MongoDB 也會在第一次寫入時自動建立資料庫，不一定需要手動建立。

---

## 4. 驗證設定

### 確認 vault-admin 可以建立帳號

```javascript
use admin
db.createUser({
  user: "test-dynamic-user",
  pwd: "test-password",
  roles: [{ role: "readWrite", db: "vaultdemo" }]
})

// 驗證後刪除
db.dropUser("test-dynamic-user")
```

### 確認 Vault 可以連線 MongoDB

在完成 VAULT_SETUP.md 的設定後，執行：
```bash
vault write -force database/config/mongodb/rotate-root
vault read database/creds/mongo-role
```

若成功回傳 `username` 和 `password`，表示 Vault 可以正常連線 MongoDB 並建立動態帳號。

---

## 5. 動態帳號說明

Vault 動態建立的 MongoDB 帳號具有以下特性：

| 項目 | 說明 |
|------|------|
| 帳號格式 | `v-userpass-{vault-user}-mongo-role-{timestamp}` |
| 建立者 | Vault 自動建立，不需手動操作 |
| 存活時間 | 依 Role 的 `default_ttl` 設定（預設 1 小時） |
| 到期行為 | Vault 自動從 MongoDB 刪除帳號 |
| 權限 | 依 Role 的 `creation_statements` 設定（readWrite on vaultdemo） |

### 查看目前存在的動態帳號

```javascript
use admin
db.getUsers()
```

輸出中可以看到 Vault 建立的臨時帳號，格式為 `v-userpass-*`，這些帳號會在 TTL 到期後自動消失。

---

## 6. 透過應用程式新增資料並用 mongosh 驗證

### 步驟一：確認 vault-admin 具備讀寫權限

`vault-admin` 需要同時擁有以下兩個角色：

| 角色 | 用途 |
|------|------|
| `userAdminAnyDatabase` | 建立 / 刪除動態帳號 |
| `readWriteAnyDatabase` | 讀寫任意資料庫的資料 |

確認現有角色：
```javascript
use admin
db.getUser("vault-admin")
```

若 `roles` 清單中缺少 `readWriteAnyDatabase`，執行以下指令補上：
```javascript
use admin
db.grantRolesToUser("vault-admin", [
  { role: "readWriteAnyDatabase", db: "admin" }
])
```

> **注意：** `userAdminAnyDatabase` 僅允許管理帳號，**不包含**資料讀寫權限。兩個角色需同時存在。

---

### 步驟二：透過應用程式新增資料

1. 登入應用程式後，前往**動態憑證**頁面申請一組憑證
2. 進入**資料瀏覽器**（`/data`）
3. 左下角「指定 Collection」欄位輸入 `demo`，按搜尋圖示
4. 展開頁面下方**「新增文件」**，輸入 JSON 並送出：

```json
{"name": "測試", "value": 123}
```

MongoDB 在第一次寫入時會自動建立 Collection，不需要事先手動建立。

---

### 步驟三：用 mongosh 驗證資料

```bash
mongosh -u vault-admin -p <vault-admin密碼> --authenticationDatabase admin
```

```javascript
use vaultdemo
db.demo.find().pretty()
```

預期輸出：
```json
{
  "_id": { "$oid": "..." },
  "name": "測試",
  "value": 123
}
```
