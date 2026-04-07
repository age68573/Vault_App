# Vault 前置設定指南

本文件說明部署展示應用程式前，需要在 HashiCorp Vault 完成的所有設定。

---

## 目錄

1. [前置確認](#前置確認)
2. [啟用 Userpass 認證方法](#1-啟用-userpass-認證方法)
3. [建立 Policy](#2-建立-policy)
4. [建立使用者](#3-建立使用者)
5. [啟用 Database Secrets Engine](#4-啟用-database-secrets-engine)
6. [設定 MongoDB 連線](#5-設定-mongodb-連線)
7. [建立 MongoDB Role](#6-建立-mongodb-role)
8. [驗證設定](#7-驗證設定)
9. [更新 Policy（不重建使用者）](#8-更新-policy不重建使用者)

---

## 前置確認

- Vault 伺服器已啟動並處於 Unsealed 狀態
- 已有 root token 或具備足夠權限的管理 token
- MongoDB 伺服器已啟動並啟用身份驗證（見 MONGODB_SETUP.md）

```bash
# 確認 Vault 狀態
vault status

# 設定環境變數（依實際環境調整）
export VAULT_ADDR="https://10.107.85.84:8200"
export VAULT_NAMESPACE="root"          # Enterprise 版才需要，OSS 可省略
export VAULT_TOKEN="<root-token>"
export VAULT_SKIP_VERIFY=true          # 自簽憑證環境使用
```

---

## 1. 啟用 Userpass 認證方法

```bash
vault auth enable userpass
```

確認已啟用：
```bash
vault auth list
```

---

## 2. 建立 Policy

Policy 定義使用者 Token 可以對 Vault 執行哪些操作。

```bash
vault policy write mongo-demo-policy - <<EOF
# 申請 MongoDB 動態憑證
path "database/creds/mongo-role" {
  capabilities = ["read"]
}

# 查詢 Lease 詳細資訊
path "sys/leases/lookup" {
  capabilities = ["update", "sudo"]
}

# 列出指定前綴下的所有活躍 Lease（需要 sudo + list）
path "sys/leases/lookup/database/creds/mongo-role" {
  capabilities = ["sudo", "list"]
}

# 續期 Lease
path "sys/leases/renew" {
  capabilities = ["update"]
}

# 撤銷 Lease
path "sys/leases/revoke" {
  capabilities = ["update"]
}

# 查詢自身 Token 資訊
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# 撤銷自身 Token（登出時使用）
path "auth/token/revoke-self" {
  capabilities = ["update"]
}
EOF
```

確認 Policy 內容：
```bash
vault policy read mongo-demo-policy
```

---

## 3. 建立使用者

```bash
vault write auth/userpass/users/jeremy \
    password="your-password" \
    policies="mongo-demo-policy"
```

> 密碼請依實際需求設定，此處僅為範例。

確認使用者已建立：
```bash
vault read auth/userpass/users/jeremy
```

---

## 4. 啟用 Database Secrets Engine

```bash
vault secrets enable database
```

確認已啟用：
```bash
vault secrets list
```

---

## 5. 設定 MongoDB 連線

Vault 使用此設定連線 MongoDB，以便動態建立和刪除帳號。

```bash
vault write database/config/mongodb \
    plugin_name=mongodb-database-plugin \
    allowed_roles="mongo-role" \
    connection_url="mongodb://{{username}}:{{password}}@10.107.85.88:27017/admin" \
    username="vault-admin" \
    password="vault-admin-password"
```

| 參數 | 說明 |
|------|------|
| `plugin_name` | 固定使用 `mongodb-database-plugin` |
| `allowed_roles` | 允許使用此連線的 Role 名稱 |
| `connection_url` | MongoDB 連線字串，`{{username}}` 和 `{{password}}` 為 Vault 佔位符 |
| `username` | Vault 用來管理動態帳號的 MongoDB 管理帳號（見 MONGODB_SETUP.md） |
| `password` | 對應的管理帳號密碼 |

測試 MongoDB 連線是否正常：
```bash
vault write -force database/config/mongodb/rotate-root
```

---

## 6. 建立 MongoDB Role

Role 定義 Vault 動態產生的 MongoDB 帳號所擁有的權限。

```bash
vault write database/roles/mongo-role \
    db_name=mongodb \
    creation_statements='{"db":"admin","roles":[{"role":"readWrite","db":"vaultdemo"}]}' \
    default_ttl="1h" \
    max_ttl="24h"
```

| 參數 | 值 | 說明 |
|------|-----|------|
| `db_name` | `mongodb` | 對應 `database/config/` 的設定名稱 |
| `creation_statements` | JSON | 動態帳號的建立語句，此處給予 `vaultdemo` 資料庫的 readWrite 權限 |
| `default_ttl` | `1h` | 預設存活時間，申請後 1 小時到期 |
| `max_ttl` | `24h` | 最長可續期至 24 小時 |

---

## 7. 驗證設定

### 測試登入
```bash
vault login -method=userpass \
    -namespace=root \
    username=jeremy
```

### 測試申請動態憑證
```bash
vault read database/creds/mongo-role
```

預期回應：
```
Key                Value
---                -----
lease_id           database/creds/mongo-role/xxxxxxxx
lease_duration     1h
lease_renewable    true
password           A1a-xxxxxxxxxxxxxxxx
username           v-userpass-jeremy-mongo-role-xxxxxxxx
```

### 測試 LIST Lease（需登入後用 userpass token 測試）
```bash
TOKEN=$(vault login -method=userpass username=jeremy -format=json | python -m json.tool | grep client_token | awk -F'"' '{print $4}')

curl -k -s -X LIST \
  ${VAULT_ADDR}/v1/sys/leases/lookup/database/creds/mongo-role \
  -H "X-Vault-Namespace: root" \
  -H "X-Vault-Token: ${TOKEN}" | python -m json.tool
```

預期回應包含 `"data": { "keys": [...] }`。

---

## 8. 更新 Policy（不重建使用者）

若需要修改 Policy（例如新增或移除權限），直接重新執行 `vault policy write` 即可，**不需要重建使用者**。

```bash
vault policy write mongo-demo-policy - <<EOF
# ... 新的 policy 內容
EOF
```

> **重要：** Policy 更新後，現有的 Token 不會立即套用新權限，需要**登出再重新登入**取得新 Token 才會生效。
