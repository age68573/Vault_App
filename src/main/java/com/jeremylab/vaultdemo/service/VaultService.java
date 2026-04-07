package com.jeremylab.vaultdemo.service;

import com.jeremylab.vaultdemo.config.AppConfig;
import com.jeremylab.vaultdemo.model.DynamicCredential;
import com.jeremylab.vaultdemo.model.LeaseInfo;
import com.jeremylab.vaultdemo.model.VaultToken;
import com.jeremylab.vaultdemo.util.JsonUtil;
import com.jeremylab.vaultdemo.util.VaultHttpClient;
import jakarta.enterprise.context.ApplicationScoped;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Vault API 服務類別。
 * 封裝所有對 HashiCorp Vault REST API 的呼叫，使用無狀態設計。
 * Token 由呼叫端（Servlet/Session）傳入，不儲存於此類別中。
 */
@ApplicationScoped
public class VaultService {

    private static final Logger LOG = LoggerFactory.getLogger(VaultService.class);

    private final VaultHttpClient client;

    public VaultService() {
        this.client = new VaultHttpClient();
    }

    /**
     * 使用 Vault userpass 認證方法登入，取得 Token。
     * 呼叫 POST /v1/auth/userpass/login/{username}
     *
     * @param username Vault 使用者名稱
     * @param password Vault 使用者密碼
     * @return VaultToken 包含 client_token、TTL 及政策清單
     * @throws VaultAuthException 若帳號或密碼錯誤
     * @throws VaultException     其他 Vault API 錯誤
     */
    public VaultToken login(String username, String password) throws VaultException {
        String path = "/v1/auth/userpass/login/" + username;
        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("password", password);
        String body = JsonUtil.toJson(bodyMap);

        LOG.info("Vault 登入：使用者 '{}'", username);
        String response = client.post(path, body, null);

        Map<String, Object> json = JsonUtil.parseObject(response);
        Map<String, Object> auth = JsonUtil.get(json, "auth");
        if (auth == null) {
            throw new VaultException("Vault 登入回應格式異常：找不到 auth 區塊");
        }
        VaultToken token = VaultToken.fromAuthBlock(auth);
        LOG.info("Vault 登入成功：使用者 '{}'，accessor '{}'", username, token.getAccessor());
        return token;
    }

    /**
     * 查詢目前 Token 的詳細資訊（更新剩餘 TTL）。
     * 呼叫 GET /v1/auth/token/lookup-self
     *
     * @param vaultToken 目前的 Vault Token
     * @return 更新後的 VaultToken 資訊
     * @throws VaultException Vault API 錯誤
     */
    public VaultToken lookupSelf(String vaultToken) throws VaultException {
        String path = "/v1/auth/token/lookup-self";
        String response = client.get(path, vaultToken);

        Map<String, Object> json = JsonUtil.parseObject(response);
        Map<String, Object> data = JsonUtil.get(json, "data");
        if (data == null) {
            throw new VaultException("Vault Token lookup 回應格式異常");
        }
        return VaultToken.fromLookupBlock(data);
    }

    /**
     * 向 Vault Database Secrets Engine 申請 MongoDB 動態憑證。
     * 呼叫 GET /v1/database/creds/{role}
     *
     * @param vaultToken 目前的 Vault Token
     * @return DynamicCredential 包含帳號、密碼、Lease ID 及 TTL
     * @throws VaultException Vault API 錯誤
     */
    public DynamicCredential getDatabaseCredential(String vaultToken) throws VaultException {
        String path = "/v1/database/creds/" + AppConfig.VAULT_DB_ROLE;
        LOG.info("申請 MongoDB 動態憑證：role '{}'", AppConfig.VAULT_DB_ROLE);
        String response = client.get(path, vaultToken);

        Map<String, Object> json = JsonUtil.parseObject(response);
        DynamicCredential cred = DynamicCredential.fromVaultResponse(json);
        LOG.info("動態憑證申請成功：lease_id '{}', username '{}', ttl {}s",
                cred.getLeaseId(), cred.getUsername(), cred.getLeaseDuration());
        return cred;
    }

    /**
     * 查詢特定 Lease 的詳細資訊。
     * 呼叫 PUT /v1/sys/leases/lookup
     *
     * @param vaultToken 目前的 Vault Token
     * @param leaseId    要查詢的 Lease ID
     * @return LeaseInfo 租約資訊
     * @throws VaultException Vault API 錯誤
     */
    public LeaseInfo lookupLease(String vaultToken, String leaseId) throws VaultException {
        String path = "/v1/sys/leases/lookup";
        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("lease_id", leaseId);
        String body = JsonUtil.toJson(bodyMap);

        String response = client.put(path, body, vaultToken);
        Map<String, Object> json = JsonUtil.parseObject(response);

        // Vault 回應可能在根層級或 data 區塊中
        Map<String, Object> data = JsonUtil.get(json, "data");
        if (data != null) {
            return LeaseInfo.fromVaultResponse(data);
        }
        return LeaseInfo.fromVaultResponse(json);
    }

    /**
     * 列出目前使用者在 database/ 路徑下所有活躍的 Lease。
     * 使用 PUT /v1/sys/leases/lookup 查詢已知的 Lease ID 清單。
     *
     * 注意：Vault OSS 的 LIST leases 需要 root token 或 sudo capability。
     * 此方法嘗試使用 /v1/sys/leases/lookup 搭配前綴查詢。
     *
     * @param vaultToken   目前的 Vault Token
     * @param leaseIds     要查詢的 Lease ID 清單（由應用程式維護）
     * @return LeaseInfo 清單（僅包含仍有效的 Lease）
     */
    public List<LeaseInfo> lookupLeases(String vaultToken, List<String> leaseIds) {
        List<LeaseInfo> result = new ArrayList<>();
        for (String leaseId : leaseIds) {
            try {
                LeaseInfo info = lookupLease(vaultToken, leaseId);
                if (!info.isExpired()) {
                    result.add(info);
                }
            } catch (VaultException e) {
                // Lease 不存在或已過期，略過
                LOG.debug("Lease 已失效或不存在：{}", leaseId);
            }
        }
        return result;
    }

    /**
     * 透過 Vault LIST API 取得指定前綴下所有活躍的 Lease ID。
     * 需要 Policy 具有 sudo + list capability。
     * 呼叫 LIST /v1/sys/leases/lookup/{prefix}
     *
     * @param vaultToken Vault Token（需具備 sudo 權限）
     * @param prefix     Lease 路徑前綴，例如 database/creds/mongo-role
     * @return Lease ID 清單
     * @throws VaultException Vault API 錯誤
     */
    @SuppressWarnings("unchecked")
    public List<String> listLeaseIdsByPrefix(String vaultToken, String prefix) throws VaultException {
        String path = "/v1/sys/leases/lookup/" + prefix;
        LOG.debug("LIST Leases：{}", path);
        String response = client.list(path, vaultToken);

        Map<String, Object> json = JsonUtil.parseObject(response);
        Object keys = json.get("keys");
        List<String> result = new ArrayList<>();
        if (keys instanceof List) {
            for (Object key : (List<Object>) keys) {
                if (key instanceof String) {
                    result.add("database/creds/" + AppConfig.VAULT_DB_ROLE + "/" + key);
                }
            }
        }
        LOG.debug("LIST Leases 取得 {} 筆", result.size());
        return result;
    }

    /**
     * 透過 Vault LIST API 取得活躍 Lease 並查詢詳細資訊。
     * 若 LIST 失敗（權限不足），退回使用 fallbackLeaseIds 清單。
     *
     * @param vaultToken        目前的 Vault Token
     * @param fallbackLeaseIds  備用的已知 Lease ID 清單（來自 Session）
     * @return LeaseInfo 清單
     */
    public List<LeaseInfo> listAndLookupLeases(String vaultToken, List<String> fallbackLeaseIds) {
        try {
            List<String> ids = listLeaseIdsByPrefix(vaultToken,
                    "database/creds/" + AppConfig.VAULT_DB_ROLE);
            return lookupLeases(vaultToken, ids);
        } catch (VaultException e) {
            LOG.warn("LIST Leases 失敗（權限不足？），退回 Session 清單：{}", e.getMessage());
            return lookupLeases(vaultToken, fallbackLeaseIds);
        }
    }

    /**
     * 續期指定的 Lease。
     * 呼叫 PUT /v1/sys/leases/renew
     *
     * @param vaultToken       目前的 Vault Token
     * @param leaseId          要續期的 Lease ID
     * @param incrementSeconds 續期增加的秒數（0 代表使用 Vault 預設）
     * @return 更新後的 LeaseInfo
     * @throws VaultException Vault API 錯誤
     */
    public LeaseInfo renewLease(String vaultToken, String leaseId, int incrementSeconds)
            throws VaultException {
        String path = "/v1/sys/leases/renew";
        Map<String, Object> bodyMap = new HashMap<>();
        bodyMap.put("lease_id", leaseId);
        if (incrementSeconds > 0) {
            bodyMap.put("increment", incrementSeconds);
        }
        String body = JsonUtil.toJson(bodyMap);

        LOG.info("續期 Lease：{}", leaseId);
        String response = client.put(path, body, vaultToken);
        Map<String, Object> json = JsonUtil.parseObject(response);

        LeaseInfo info = new LeaseInfo();
        info.setLeaseId(leaseId);
        info.setTtl(toLong(json.get("lease_duration")));
        info.setRenewable(Boolean.TRUE.equals(json.get("renewable")));
        LOG.info("Lease 續期成功：{}，新 TTL {}s", leaseId, info.getTtl());
        return info;
    }

    /**
     * 撤銷指定的 Lease，立即使動態憑證失效。
     * 呼叫 PUT /v1/sys/leases/revoke
     *
     * @param vaultToken 目前的 Vault Token
     * @param leaseId    要撤銷的 Lease ID
     * @throws VaultException Vault API 錯誤
     */
    public void revokeLease(String vaultToken, String leaseId) throws VaultException {
        String path = "/v1/sys/leases/revoke";
        Map<String, String> bodyMap = new HashMap<>();
        bodyMap.put("lease_id", leaseId);
        String body = JsonUtil.toJson(bodyMap);

        LOG.info("撤銷 Lease：{}", leaseId);
        client.put(path, body, vaultToken);
        LOG.info("Lease 撤銷成功：{}", leaseId);
    }

    /**
     * 撤銷目前的 Vault Token（登出時呼叫）。
     * 呼叫 POST /v1/auth/token/revoke-self
     * 此操作採盡力而為模式，失敗時僅記錄日誌，不拋出例外。
     *
     * @param vaultToken 要撤銷的 Vault Token
     */
    public void revokeSelf(String vaultToken) {
        try {
            LOG.info("撤銷 Vault Token（登出）");
            client.post("/v1/auth/token/revoke-self", null, vaultToken);
            LOG.info("Vault Token 撤銷成功");
        } catch (Exception e) {
            LOG.warn("Vault Token 撤銷失敗（已忽略）：{}", e.getMessage());
        }
    }

    private static long toLong(Object val) {
        if (val instanceof Number) return ((Number) val).longValue();
        return 0L;
    }
}
