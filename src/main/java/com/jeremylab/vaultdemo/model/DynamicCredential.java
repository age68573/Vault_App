package com.jeremylab.vaultdemo.model;

import java.io.Serializable;
import java.util.Map;

/**
 * Vault 動態 MongoDB 憑證模型。
 * 儲存在 HTTP Session 中，用於建立 MongoDB 連線。
 * 憑證具有有限存活時間（TTL），到期後無法存取資料庫。
 */
public class DynamicCredential implements Serializable {

    private static final long serialVersionUID = 1L;

    /** Vault Lease ID，用於續期或撤銷此憑證 */
    private String leaseId;

    /** MongoDB 動態帳號（由 Vault 生成） */
    private String username;

    /** MongoDB 動態密碼（由 Vault 生成，敏感資料） */
    private String password;

    /** 憑證存活時間（秒） */
    private long leaseDuration;

    /** 是否可續期 */
    private boolean renewable;

    /** 憑證申請時間（Unix Epoch 秒），由應用程式記錄 */
    private long issuedAt;

    public DynamicCredential() {}

    /**
     * 從 Vault database/creds API 回應建立 DynamicCredential 物件。
     *
     * @param response Vault 完整 JSON 回應（已解析為 Map）
     * @return DynamicCredential 實例
     */
    @SuppressWarnings("unchecked")
    public static DynamicCredential fromVaultResponse(Map<String, Object> response) {
        DynamicCredential cred = new DynamicCredential();
        cred.leaseId       = (String) response.getOrDefault("lease_id", "");
        cred.renewable     = Boolean.TRUE.equals(response.get("renewable"));
        cred.leaseDuration = toLong(response.get("lease_duration"));
        cred.issuedAt      = System.currentTimeMillis() / 1000L;

        Object data = response.get("data");
        if (data instanceof Map) {
            Map<String, Object> dataMap = (Map<String, Object>) data;
            cred.username = (String) dataMap.getOrDefault("username", "");
            cred.password = (String) dataMap.getOrDefault("password", "");
        }
        return cred;
    }

    /** 計算憑證剩餘有效秒數。 */
    public long getRemainingTtlSeconds() {
        if (leaseDuration <= 0) return 0;
        long elapsed = (System.currentTimeMillis() / 1000L) - issuedAt;
        return Math.max(0, leaseDuration - elapsed);
    }

    /** 判斷憑證是否已過期。 */
    public boolean isExpired() {
        return getRemainingTtlSeconds() <= 0;
    }

    private static long toLong(Object val) {
        if (val instanceof Number) return ((Number) val).longValue();
        if (val instanceof String) {
            try { return Long.parseLong((String) val); } catch (NumberFormatException ignored) {}
        }
        return 0L;
    }

    // --- Getters / Setters ---

    public String getLeaseId()              { return leaseId; }
    public void setLeaseId(String id)       { this.leaseId = id; }

    public String getUsername()             { return username; }
    public void setUsername(String u)       { this.username = u; }

    public String getPassword()             { return password; }
    public void setPassword(String p)       { this.password = p; }

    public long getLeaseDuration()          { return leaseDuration; }
    public void setLeaseDuration(long d)    { this.leaseDuration = d; }

    public boolean isRenewable()            { return renewable; }
    public void setRenewable(boolean r)     { this.renewable = r; }

    public long getIssuedAt()               { return issuedAt; }
    public void setIssuedAt(long t)         { this.issuedAt = t; }
}
