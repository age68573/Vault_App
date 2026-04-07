package com.jeremylab.vaultdemo.service;

/**
 * Vault 操作例外基底類別。
 * 所有與 Vault API 互動產生的例外皆繼承此類別。
 */
public class VaultException extends Exception {

    private final int httpStatus;

    public VaultException(String message) {
        super(message);
        this.httpStatus = 0;
    }

    public VaultException(String message, int httpStatus) {
        super(message);
        this.httpStatus = httpStatus;
    }

    public VaultException(String message, Throwable cause) {
        super(message, cause);
        this.httpStatus = 0;
    }

    /** 取得 Vault API 回傳的 HTTP 狀態碼（若無則為 0）。 */
    public int getHttpStatus() {
        return httpStatus;
    }
}
