package com.jeremylab.vaultdemo.service;

import com.jeremylab.vaultdemo.model.AuditEntry;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 應用程式層稽核日誌服務。
 * 維護一個記憶體內的環形緩衝區，記錄最多 500 筆 Vault 操作記錄。
 *
 * 注意：此服務記錄應用程式層的操作歷史，並非 Vault 官方 Audit Device 的替代品。
 * 如需完整的 Vault 稽核日誌，請在 Vault 伺服器上啟用 file 或 syslog audit device。
 */
@ApplicationScoped
public class AuditLogService {

    private static final int MAX_ENTRIES = 500;

    /** 使用雙端佇列作為環形緩衝區，最新記錄在前端 */
    private final Deque<AuditEntry> log = new ArrayDeque<>(MAX_ENTRIES);

    /**
     * 記錄一筆稽核記錄。
     *
     * @param entry 要記錄的稽核項目
     */
    public synchronized void record(AuditEntry entry) {
        if (log.size() >= MAX_ENTRIES) {
            log.removeLast(); // 移除最舊的記錄
        }
        log.addFirst(entry); // 最新記錄放最前
    }

    /**
     * 取得最近的稽核記錄（最新在前）。
     *
     * @param limit 最多回傳幾筆（0 或負數代表全部）
     * @return 稽核記錄清單
     */
    public synchronized List<AuditEntry> getRecent(int limit) {
        List<AuditEntry> all = new ArrayList<>(log);
        if (limit <= 0 || limit >= all.size()) return all;
        return all.subList(0, limit);
    }

    /**
     * 依操作類型過濾稽核記錄。
     *
     * @param operation 操作類型字串（若為 null 或空字串則回傳全部）
     * @param limit     最多回傳幾筆
     * @return 過濾後的稽核記錄清單
     */
    public synchronized List<AuditEntry> getByOperation(String operation, int limit) {
        if (operation == null || operation.isEmpty()) {
            return getRecent(limit);
        }
        List<AuditEntry> filtered = log.stream()
                .filter(e -> operation.equals(e.getOperation()))
                .collect(Collectors.toList());
        if (limit <= 0 || limit >= filtered.size()) return filtered;
        return filtered.subList(0, limit);
    }

    /**
     * 依使用者名稱過濾稽核記錄。
     *
     * @param username Vault 使用者名稱
     * @param limit    最多回傳幾筆
     * @return 過濾後的稽核記錄清單
     */
    public synchronized List<AuditEntry> getByUser(String username, int limit) {
        if (username == null || username.isEmpty()) {
            return getRecent(limit);
        }
        List<AuditEntry> filtered = log.stream()
                .filter(e -> username.equals(e.getVaultUsername()))
                .collect(Collectors.toList());
        if (limit <= 0 || limit >= filtered.size()) return filtered;
        return filtered.subList(0, limit);
    }

    /** 取得目前記錄總筆數。 */
    public synchronized int getCount() {
        return log.size();
    }
}
