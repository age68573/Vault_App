package com.jeremylab.vaultdemo.service;

/**
 * Vault 身份驗證失敗例外。
 * 當使用者帳號或密碼錯誤，或 Token 已失效時拋出。
 */
public class VaultAuthException extends VaultException {

    public VaultAuthException(String message) {
        super(message, 403);
    }

    public VaultAuthException(String message, int httpStatus) {
        super(message, httpStatus);
    }
}
