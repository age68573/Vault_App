package com.jeremylab.vaultdemo.model;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Map;

/**
 * Vault Lease 資訊模型。
 * 代表一筆 Vault 動態密鑰的租約記錄，包含到期時間與續期狀態。
 */
public class LeaseInfo implements Serializable {

    private static final long serialVersionUID = 1L;

    /** Lease ID */
    private String leaseId;

    /** 剩餘存活時間（秒） */
    private long ttl;

    /** 是否可續期 */
    private boolean renewable;

    /** 發行時間（ISO 8601 字串，由 Vault 提供） */
    private String issueTime;

    /** 到期時間（ISO 8601 字串，由 Vault 提供） */
    private String expireTime;

    public LeaseInfo() {}

    /**
     * 從 Vault sys/leases/lookup API 回應建立 LeaseInfo 物件。
     *
     * @param response Vault 回應的 data 區塊（已解析為 Map）
     * @return LeaseInfo 實例
     */
    public static LeaseInfo fromVaultResponse(Map<String, Object> response) {
        LeaseInfo info = new LeaseInfo();
        info.leaseId    = (String) response.getOrDefault("id", "");
        info.ttl        = toLong(response.get("ttl"));
        info.renewable  = Boolean.TRUE.equals(response.get("renewable"));
        info.issueTime  = (String) response.getOrDefault("issue_time", "");
        info.expireTime = (String) response.getOrDefault("expire_time", "");
        return info;
    }

    /**
     * 計算原始租約總時長（秒），由 issueTime 與 expireTime 之差得出。
     * 若時間戳記解析失敗，退回使用 ttl（此時進度條從 100% 起算）。
     */
    public long getTotalDurationSeconds() {
        if (issueTime != null && !issueTime.isEmpty()
                && expireTime != null && !expireTime.isEmpty()) {
            try {
                OffsetDateTime issue  = OffsetDateTime.parse(issueTime);
                OffsetDateTime expire = OffsetDateTime.parse(expireTime);
                long duration = ChronoUnit.SECONDS.between(issue, expire);
                if (duration > 0) return duration;
            } catch (Exception ignored) {}
        }
        return ttl > 0 ? ttl : 3600;
    }

    /** 判斷此 Lease 剩餘時間是否低於警戒值（60 秒）。 */
    public boolean isAlmostExpired() {
        return ttl > 0 && ttl < 60;
    }

    /** 判斷此 Lease 是否已過期。 */
    public boolean isExpired() {
        return ttl <= 0;
    }

    /** 取得供顯示用的截短 Lease ID（前 20 字元 + ...）。 */
    public String getShortLeaseId() {
        if (leaseId == null || leaseId.length() <= 20) return leaseId;
        return leaseId.substring(0, 20) + "...";
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

    public long getTtl()                    { return ttl; }
    public void setTtl(long ttl)            { this.ttl = ttl; }

    public boolean isRenewable()            { return renewable; }
    public void setRenewable(boolean r)     { this.renewable = r; }

    public String getIssueTime()            { return issueTime; }
    public void setIssueTime(String t)      { this.issueTime = t; }

    public String getExpireTime()           { return expireTime; }
    public void setExpireTime(String t)     { this.expireTime = t; }
}
