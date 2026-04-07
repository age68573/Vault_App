package com.jeremylab.vaultdemo.util;

import com.jeremylab.vaultdemo.config.AppConfig;
import com.jeremylab.vaultdemo.service.VaultAuthException;
import com.jeremylab.vaultdemo.service.VaultException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

/**
 * Vault REST API HTTP 客戶端。
 * 封裝 Java 11 HttpClient，統一處理 Vault Token 標頭、命名空間、
 * 逾時設定及 HTTP 錯誤碼對應至例外類別。
 */
public class VaultHttpClient {

    private static final Logger LOG = LoggerFactory.getLogger(VaultHttpClient.class);

    private static final String HEADER_VAULT_TOKEN     = "X-Vault-Token";
    private static final String HEADER_VAULT_NAMESPACE = "X-Vault-Namespace";
    private static final String HEADER_CONTENT_TYPE    = "Content-Type";
    private static final String CONTENT_TYPE_JSON      = "application/json";

    private final HttpClient httpClient;
    private final String vaultAddr;

    public VaultHttpClient() {
        this.vaultAddr = AppConfig.VAULT_ADDR;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(AppConfig.HTTP_TIMEOUT_SECONDS))
                .build();
    }

    /**
     * 發送 HTTP POST 請求至 Vault。
     *
     * @param path      API 路徑，例如 /v1/auth/userpass/login/admin
     * @param jsonBody  請求內容（JSON 字串），可為 null
     * @param vaultToken Vault Token（登入前可為 null）
     * @return 回應內容字串
     * @throws VaultException 若 HTTP 狀態碼為 4xx 或 5xx
     */
    public String post(String path, String jsonBody, String vaultToken) throws VaultException {
        HttpRequest.Builder builder = baseBuilder(path, vaultToken)
                .POST(body(jsonBody));
        return send(builder.build(), path);
    }

    /**
     * 發送 HTTP GET 請求至 Vault。
     */
    public String get(String path, String vaultToken) throws VaultException {
        HttpRequest.Builder builder = baseBuilder(path, vaultToken).GET();
        return send(builder.build(), path);
    }

    /**
     * 發送 HTTP PUT 請求至 Vault。
     */
    public String put(String path, String jsonBody, String vaultToken) throws VaultException {
        HttpRequest.Builder builder = baseBuilder(path, vaultToken)
                .PUT(body(jsonBody));
        return send(builder.build(), path);
    }

    /**
     * 發送 HTTP LIST 請求至 Vault（自訂方法）。
     * Vault 使用 HTTP LIST 方法列舉資源。
     */
    public String list(String path, String vaultToken) throws VaultException {
        HttpRequest.Builder builder = baseBuilder(path, vaultToken)
                .method("LIST", HttpRequest.BodyPublishers.noBody());
        return send(builder.build(), path);
    }

    // --- 私用方法 ---

    private HttpRequest.Builder baseBuilder(String path, String vaultToken) {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(vaultAddr + path))
                .timeout(Duration.ofSeconds(AppConfig.HTTP_TIMEOUT_SECONDS))
                .header(HEADER_CONTENT_TYPE, CONTENT_TYPE_JSON);

        if (vaultToken != null && !vaultToken.isEmpty()) {
            builder.header(HEADER_VAULT_TOKEN, vaultToken);
        }
        if (!AppConfig.VAULT_NAMESPACE.isEmpty()) {
            builder.header(HEADER_VAULT_NAMESPACE, AppConfig.VAULT_NAMESPACE);
        }
        return builder;
    }

    private HttpRequest.BodyPublisher body(String jsonBody) {
        if (jsonBody == null || jsonBody.isEmpty()) {
            return HttpRequest.BodyPublishers.noBody();
        }
        return HttpRequest.BodyPublishers.ofString(jsonBody);
    }

    private String send(HttpRequest request, String path) throws VaultException {
        try {
            LOG.debug("Vault API 請求：{} {}", request.method(), path);
            HttpResponse<String> response =
                    httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            int status = response.statusCode();
            LOG.debug("Vault API 回應：HTTP {} for {}", status, path);

            if (status == 200 || status == 204) {
                return response.body();
            } else if (status == 403) {
                throw new VaultAuthException("Vault 身份驗證失敗（HTTP 403）：" + path, 403);
            } else if (status == 404) {
                throw new VaultException("Vault 資源不存在（HTTP 404）：" + path, 404);
            } else {
                String body = response.body();
                throw new VaultException(
                        "Vault API 錯誤（HTTP " + status + "）：" + path + " - " + body, status);
            }
        } catch (VaultException e) {
            throw e;
        } catch (Exception e) {
            LOG.error("Vault HTTP 連線錯誤：{}", e.getMessage(), e);
            throw new VaultException("無法連線至 Vault（" + vaultAddr + path + "）：" + e.getMessage(), e);
        }
    }
}
