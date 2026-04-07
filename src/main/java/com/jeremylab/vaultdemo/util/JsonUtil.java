package com.jeremylab.vaultdemo.util;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.List;
import java.util.Map;

/**
 * JSON 工具類別，封裝 Jackson ObjectMapper 的常用操作。
 * 用於解析 Vault REST API 的 JSON 回應。
 */
public final class JsonUtil {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private JsonUtil() {}

    /**
     * 將 JSON 字串解析為 Map&lt;String, Object&gt;。
     *
     * @param json JSON 字串
     * @return 解析結果 Map
     * @throws IllegalArgumentException 若 JSON 格式錯誤
     */
    public static Map<String, Object> parseObject(String json) {
        try {
            return MAPPER.readValue(json, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new IllegalArgumentException("JSON 解析失敗：" + e.getMessage(), e);
        }
    }

    /**
     * 將 JSON 字串解析為 List&lt;Map&lt;String, Object&gt;&gt;。
     *
     * @param json JSON 字串
     * @return 解析結果 List
     * @throws IllegalArgumentException 若 JSON 格式錯誤
     */
    public static List<Map<String, Object>> parseArray(String json) {
        try {
            return MAPPER.readValue(json, new TypeReference<List<Map<String, Object>>>() {});
        } catch (Exception e) {
            throw new IllegalArgumentException("JSON 陣列解析失敗：" + e.getMessage(), e);
        }
    }

    /**
     * 將物件序列化為 JSON 字串。
     *
     * @param obj 要序列化的物件
     * @return JSON 字串
     * @throws IllegalArgumentException 若序列化失敗
     */
    public static String toJson(Object obj) {
        try {
            return MAPPER.writeValueAsString(obj);
        } catch (Exception e) {
            throw new IllegalArgumentException("JSON 序列化失敗：" + e.getMessage(), e);
        }
    }

    /**
     * 從巢狀 Map 中安全地讀取深層欄位值。
     * 例如：get(map, "auth", "client_token") 等同於 map["auth"]["client_token"]
     *
     * @param map  根 Map
     * @param keys 依序的欄位鍵
     * @param <T>  預期回傳型別
     * @return 欄位值，若路徑不存在則回傳 null
     */
    @SuppressWarnings("unchecked")
    public static <T> T get(Map<String, Object> map, String... keys) {
        Object current = map;
        for (String key : keys) {
            if (!(current instanceof Map)) return null;
            current = ((Map<String, Object>) current).get(key);
        }
        return (T) current;
    }
}
