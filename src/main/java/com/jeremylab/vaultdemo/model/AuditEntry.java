package com.jeremylab.vaultdemo.model;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * 應用程式層稽核日誌記錄模型。
 * 記錄每一次 Vault API 操作，包含操作者、操作路徑、結果與錯誤訊息。
 * 注意：此為應用程式層日誌，非 Vault 官方 Audit Device 的替代品。
 */
public class AuditEntry implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final DateTimeFormatter FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** 操作類型常數 */
    public static final String OP_LOGIN        = "登入 Vault";
    public static final String OP_LOGOUT       = "登出 Vault";
    public static final String OP_GET_CREDS    = "申請動態憑證";
    public static final String OP_RENEW_LEASE  = "續期 Lease";
    public static final String OP_REVOKE_LEASE = "撤銷 Lease";
    public static final String OP_MONGO_QUERY  = "MongoDB 查詢";
    public static final String OP_MONGO_INSERT = "MongoDB 新增";
    public static final String OP_MONGO_DELETE = "MongoDB 刪除";
    public static final String OP_LOOKUP_TOKEN = "查詢 Token 資訊";

    /** 結果常數 */
    public static final String RESULT_SUCCESS = "成功";
    public static final String RESULT_FAILURE = "失敗";

    private String id;
    private LocalDateTime timestamp;
    private String operation;
    private String vaultPath;
    private String vaultUsername;
    private String leaseId;
    private String result;
    private String errorMessage;

    private AuditEntry() {}

    /**
     * 建立成功操作的稽核記錄。
     */
    public static AuditEntry success(String operation, String vaultPath,
                                     String username, String leaseId) {
        AuditEntry e = new AuditEntry();
        e.id           = UUID.randomUUID().toString();
        e.timestamp    = LocalDateTime.now();
        e.operation    = operation;
        e.vaultPath    = vaultPath;
        e.vaultUsername = username;
        e.leaseId      = leaseId;
        e.result       = RESULT_SUCCESS;
        return e;
    }

    /**
     * 建立失敗操作的稽核記錄。
     */
    public static AuditEntry failure(String operation, String vaultPath,
                                     String username, String errorMessage) {
        AuditEntry e = new AuditEntry();
        e.id           = UUID.randomUUID().toString();
        e.timestamp    = LocalDateTime.now();
        e.operation    = operation;
        e.vaultPath    = vaultPath;
        e.vaultUsername = username;
        e.leaseId      = null;
        e.result       = RESULT_FAILURE;
        e.errorMessage = errorMessage;
        return e;
    }

    /** 取得格式化的時間字串。 */
    public String getFormattedTimestamp() {
        return timestamp != null ? timestamp.format(FORMATTER) : "";
    }

    /** 判斷此記錄是否為成功操作。 */
    public boolean isSuccess() {
        return RESULT_SUCCESS.equals(result);
    }

    // --- Getters ---

    public String getId()               { return id; }
    public LocalDateTime getTimestamp() { return timestamp; }
    public String getOperation()        { return operation; }
    public String getVaultPath()        { return vaultPath; }
    public String getVaultUsername()    { return vaultUsername; }
    public String getLeaseId()          { return leaseId; }
    public String getResult()           { return result; }
    public String getErrorMessage()     { return errorMessage; }
}
