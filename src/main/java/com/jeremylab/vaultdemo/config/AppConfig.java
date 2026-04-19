package com.jeremylab.vaultdemo.config;

/**
 * 應用程式設定類別。
 * 所有設定值從 JVM 系統屬性讀取，若無則退回環境變數，最後使用預設值。
 *
 * 設定方式（優先順序由高至低）：
 *   1. JVM 啟動參數：-Dvault.addr=http://...
 *   2. 環境變數：VAULT_ADDR=http://...
 *   3. 程式碼預設值
 */
public final class AppConfig {

    /** Vault 伺服器基礎 URL，例如 http://127.0.0.1:8200 */
    public static final String VAULT_ADDR;

    /** Vault Database Secrets Engine 的角色名稱 */
    public static final String VAULT_DB_ROLE;

    /** Vault Enterprise 命名空間（OSS 版本請留空字串） */
    public static final String VAULT_NAMESPACE;

    /** 是否跳過 TLS 憑證驗證（僅供開發環境使用） */
    public static final boolean VAULT_SKIP_VERIFY;

    /** MongoDB 主機名稱或 IP */
    public static final String MONGO_HOST;

    /** MongoDB 連接埠 */
    public static final int MONGO_PORT;

    /** MongoDB 資料庫名稱 */
    public static final String MONGO_DB_NAME;

    /** 向 Vault 發送 HTTP 請求的逾時秒數 */
    public static final int HTTP_TIMEOUT_SECONDS;

    /** Vault LDAP 認證方法的掛載路徑（預設 ldap） */
    public static final String VAULT_LDAP_PATH;

    static {
        VAULT_ADDR          = get("vault.addr",          "VAULT_ADDR",          "http://127.0.0.1:8200");
        VAULT_DB_ROLE       = get("vault.db.role",       "VAULT_DB_ROLE",       "mongo-role");
        VAULT_NAMESPACE     = get("vault.namespace",     "VAULT_NAMESPACE",     "");
        VAULT_SKIP_VERIFY   = Boolean.parseBoolean(
                                get("vault.skip.verify", "VAULT_SKIP_VERIFY",   "false"));
        VAULT_LDAP_PATH     = get("vault.ldap.path",     "VAULT_LDAP_PATH",     "ldap");
        MONGO_HOST          = get("mongo.host",          "MONGO_HOST",          "127.0.0.1");
        MONGO_DB_NAME       = get("mongo.db.name",       "MONGO_DB_NAME",       "vaultdemo");
        HTTP_TIMEOUT_SECONDS = Integer.parseInt(
                                get("http.timeout",      "HTTP_TIMEOUT_SECONDS","10"));

        String portStr = get("mongo.port", "MONGO_PORT", "27017");
        int port;
        try {
            port = Integer.parseInt(portStr);
        } catch (NumberFormatException e) {
            port = 27017;
        }
        MONGO_PORT = port;
    }

    private AppConfig() {
        // 工具類別，不允許實例化
    }

    /**
     * 依優先順序讀取設定值：系統屬性 → 環境變數 → 預設值。
     */
    private static String get(String sysProp, String envVar, String defaultValue) {
        String val = System.getProperty(sysProp);
        if (val != null && !val.isEmpty()) {
            return val;
        }
        val = System.getenv(envVar);
        if (val != null && !val.isEmpty()) {
            return val;
        }
        return defaultValue;
    }
}
