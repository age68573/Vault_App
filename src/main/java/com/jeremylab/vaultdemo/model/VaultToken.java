package com.jeremylab.vaultdemo.model;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Vault Token 資訊模型。
 * 儲存在 HTTP Session 中，用於後續所有 Vault API 呼叫的身份識別。
 */
public class VaultToken implements Serializable {

    private static final long serialVersionUID = 1L;

    /** Vault Client Token（敏感資料，不顯示於日誌） */
    private String clientToken;

    /** Token 存取器（非敏感，可用於日誌與識別） */
    private String accessor;

    /** Token 建立時間（Unix Epoch 秒） */
    private long creationTime;

    /** Token 存活時間（秒），0 代表永不過期 */
    private long ttl;

    /** Token 是否可續期 */
    private boolean renewable;

    /** Token 綁定的 Vault 政策清單 */
    private List<String> policies;

    public VaultToken() {
        this.policies = new ArrayList<>();
    }

    /**
     * 從 Vault login API 的 auth 區塊建立 VaultToken 物件。
     *
     * @param authBlock Vault 回應的 auth JSON 物件（已解析為 Map）
     * @return VaultToken 實例
     */
    @SuppressWarnings("unchecked")
    public static VaultToken fromAuthBlock(Map<String, Object> authBlock) {
        VaultToken token = new VaultToken();
        token.clientToken  = (String) authBlock.getOrDefault("client_token", "");
        token.accessor     = (String) authBlock.getOrDefault("accessor", "");
        token.renewable    = Boolean.TRUE.equals(authBlock.get("renewable"));
        token.ttl          = toLong(authBlock.get("lease_duration"));
        token.creationTime = System.currentTimeMillis() / 1000L;

        Object rawPolicies = authBlock.get("policies");
        if (rawPolicies instanceof List) {
            token.policies = new ArrayList<>((List<String>) rawPolicies);
        }
        return token;
    }

    /**
     * 從 Vault token lookup-self API 的 data 區塊更新 VaultToken 資訊。
     *
     * @param dataBlock Vault 回應的 data JSON 物件（已解析為 Map）
     * @return 更新後的 VaultToken 實例
     */
    @SuppressWarnings("unchecked")
    public static VaultToken fromLookupBlock(Map<String, Object> dataBlock) {
        VaultToken token = new VaultToken();
        token.clientToken  = (String) dataBlock.getOrDefault("id", "");
        token.accessor     = (String) dataBlock.getOrDefault("accessor", "");
        token.renewable    = Boolean.TRUE.equals(dataBlock.get("renewable"));
        token.ttl          = toLong(dataBlock.get("ttl"));
        token.creationTime = System.currentTimeMillis() / 1000L;

        Object rawPolicies = dataBlock.get("policies");
        if (rawPolicies instanceof List) {
            token.policies = new ArrayList<>((List<String>) rawPolicies);
        }
        return token;
    }

    /** 計算 Token 剩餘有效秒數。 */
    public long getRemainingTtlSeconds() {
        if (ttl <= 0) return Long.MAX_VALUE; // 永不過期
        long elapsed = (System.currentTimeMillis() / 1000L) - creationTime;
        return Math.max(0, ttl - elapsed);
    }

    /** 判斷 Token 是否已過期。 */
    public boolean isExpired() {
        return ttl > 0 && getRemainingTtlSeconds() <= 0;
    }

    private static long toLong(Object val) {
        if (val instanceof Number) return ((Number) val).longValue();
        if (val instanceof String) {
            try { return Long.parseLong((String) val); } catch (NumberFormatException ignored) {}
        }
        return 0L;
    }

    // --- Getters / Setters ---

    public String getClientToken()      { return clientToken; }
    public void setClientToken(String t){ this.clientToken = t; }

    public String getAccessor()         { return accessor; }
    public void setAccessor(String a)   { this.accessor = a; }

    public long getCreationTime()       { return creationTime; }
    public void setCreationTime(long t) { this.creationTime = t; }

    public long getTtl()                { return ttl; }
    public void setTtl(long ttl)        { this.ttl = ttl; }

    public boolean isRenewable()        { return renewable; }
    public void setRenewable(boolean r) { this.renewable = r; }

    public List<String> getPolicies()   { return policies; }
    public void setPolicies(List<String> p) { this.policies = p; }
}
