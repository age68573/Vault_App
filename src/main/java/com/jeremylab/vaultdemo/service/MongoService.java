package com.jeremylab.vaultdemo.service;

import com.jeremylab.vaultdemo.config.AppConfig;
import com.jeremylab.vaultdemo.model.DynamicCredential;
import com.mongodb.MongoException;
import com.mongodb.client.*;
import jakarta.enterprise.context.ApplicationScoped;
import org.bson.Document;
import org.bson.conversions.Bson;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.Closeable;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * MongoDB 連線服務。
 * 為每個 Vault 動態憑證（以 Lease ID 為鍵）維護一個獨立的 MongoClient。
 * 憑證到期或被撤銷時，對應的 MongoClient 會被關閉並移除。
 *
 * 重要設計決策：不使用 JNDI DataSource，因為動態憑證具有短暫存活時間，
 * JNDI DataSource 會快取憑證，與動態密鑰的「零信任」設計原則相違背。
 */
@ApplicationScoped
public class MongoService implements Closeable {

    private static final Logger LOG = LoggerFactory.getLogger(MongoService.class);

    /** 以 Lease ID 為鍵，儲存對應的 MongoClient */
    private final ConcurrentHashMap<String, MongoClient> clientMap = new ConcurrentHashMap<>();

    /**
     * MongoDB 連線狀態資訊。
     */
    public static class ConnectionStatus {
        private final boolean connected;
        private final String message;
        private final long pingMs;

        public ConnectionStatus(boolean connected, String message, long pingMs) {
            this.connected = connected;
            this.message   = message;
            this.pingMs    = pingMs;
        }

        public boolean isConnected() { return connected; }
        public String getMessage()   { return message; }
        public long getPingMs()      { return pingMs; }
    }

    /**
     * 取得或建立指定動態憑證對應的 MongoClient。
     * 若 Lease ID 已存在快取中，直接回傳已建立的客戶端。
     *
     * @param cred 動態憑證（需包含 leaseId、username、password）
     * @return MongoClient 實例
     */
    public MongoClient getOrCreate(DynamicCredential cred) {
        return clientMap.computeIfAbsent(cred.getLeaseId(), id -> {
            String connStr = buildConnectionString(cred);
            LOG.info("建立 MongoDB 連線：username '{}', lease_id '{}'",
                    cred.getUsername(), cred.getLeaseId());
            return MongoClients.create(connStr);
        });
    }

    /**
     * 測試動態憑證是否可成功連線至 MongoDB。
     *
     * @param cred 動態憑證
     * @return ConnectionStatus 連線狀態
     */
    public ConnectionStatus testConnection(DynamicCredential cred) {
        if (cred == null || cred.isExpired()) {
            return new ConnectionStatus(false, "憑證已過期或不存在", 0);
        }
        try {
            MongoClient mongoClient = getOrCreate(cred);
            MongoDatabase db = mongoClient.getDatabase(AppConfig.MONGO_DB_NAME);

            long start = System.currentTimeMillis();
            Document result = db.runCommand(new Document("ping", 1));
            long pingMs = System.currentTimeMillis() - start;

            if (result.getDouble("ok") == 1.0) {
                return new ConnectionStatus(true, "連線正常", pingMs);
            } else {
                return new ConnectionStatus(false, "Ping 失敗", pingMs);
            }
        } catch (MongoException e) {
            LOG.warn("MongoDB 連線測試失敗：{}", e.getMessage());
            return new ConnectionStatus(false, "連線失敗：" + e.getMessage(), 0);
        }
    }

    /**
     * 列出資料庫中所有的 Collection 名稱。
     *
     * @param cred 動態憑證
     * @return Collection 名稱清單
     * @throws MongoException MongoDB 操作失敗
     */
    public List<String> listCollections(DynamicCredential cred) {
        MongoClient mongoClient = getOrCreate(cred);
        MongoDatabase db = mongoClient.getDatabase(AppConfig.MONGO_DB_NAME);
        List<String> names = new ArrayList<>();
        db.listCollectionNames().into(names);
        return names;
    }

    /**
     * 查詢指定 Collection 中的文件。
     *
     * @param cred           動態憑證
     * @param collectionName Collection 名稱
     * @param filterJson     MongoDB 篩選條件（JSON 字串），null 或空字串代表查詢全部
     * @param limit          最多回傳文件數（0 或負數代表使用預設 20 筆）
     * @return 查詢結果文件清單（每筆為 JSON 字串）
     */
    public List<String> findDocuments(DynamicCredential cred, String collectionName,
                                      String filterJson, int limit) {
        if (limit <= 0) limit = 20;

        MongoClient mongoClient = getOrCreate(cred);
        MongoDatabase db = mongoClient.getDatabase(AppConfig.MONGO_DB_NAME);
        MongoCollection<Document> collection = db.getCollection(collectionName);

        Document filter = (filterJson != null && !filterJson.trim().isEmpty())
                ? Document.parse(filterJson)
                : new Document();

        List<String> results = new ArrayList<>();
        try (MongoCursor<Document> cursor = collection.find(filter).limit(limit).iterator()) {
            while (cursor.hasNext()) {
                results.add(cursor.next().toJson());
            }
        }
        LOG.debug("MongoDB 查詢：collection '{}', filter '{}', 結果 {} 筆",
                collectionName, filterJson, results.size());
        return results;
    }

    /**
     * 向指定 Collection 插入一筆文件。
     *
     * @param cred           動態憑證
     * @param collectionName Collection 名稱
     * @param documentJson   要插入的文件（JSON 字串）
     * @return 插入文件的 _id 字串
     */
    public String insertDocument(DynamicCredential cred, String collectionName,
                                 String documentJson) {
        MongoClient mongoClient = getOrCreate(cred);
        MongoDatabase db = mongoClient.getDatabase(AppConfig.MONGO_DB_NAME);
        MongoCollection<Document> collection = db.getCollection(collectionName);

        Document doc = Document.parse(documentJson);
        collection.insertOne(doc);

        String insertedId = doc.getObjectId("_id").toHexString();
        LOG.info("MongoDB 新增文件：collection '{}', _id '{}'", collectionName, insertedId);
        return insertedId;
    }

    /**
     * 刪除指定 Collection 中符合篩選條件的文件。
     *
     * @param cred           動態憑證
     * @param collectionName Collection 名稱
     * @param filterJson     MongoDB 篩選條件（JSON 字串）
     * @return 刪除的文件筆數
     */
    public long deleteDocuments(DynamicCredential cred, String collectionName,
                                String filterJson) {
        MongoClient mongoClient = getOrCreate(cred);
        MongoDatabase db = mongoClient.getDatabase(AppConfig.MONGO_DB_NAME);
        MongoCollection<Document> collection = db.getCollection(collectionName);

        Document filter = Document.parse(filterJson);
        long count = collection.deleteMany(filter).getDeletedCount();
        LOG.info("MongoDB 刪除文件：collection '{}', filter '{}', 刪除 {} 筆",
                collectionName, filterJson, count);
        return count;
    }

    /**
     * 關閉並移除指定 Lease ID 對應的 MongoClient。
     * 應在 Lease 被撤銷時呼叫。
     *
     * @param leaseId 要關閉的 Lease ID
     */
    public void closeClient(String leaseId) {
        MongoClient client = clientMap.remove(leaseId);
        if (client != null) {
            try {
                client.close();
                LOG.info("已關閉 MongoDB 連線：lease_id '{}'", leaseId);
            } catch (Exception e) {
                LOG.warn("關閉 MongoDB 連線時發生錯誤：{}", e.getMessage());
            }
        }
    }

    /**
     * 應用程式關閉時，清除所有 MongoClient 連線。
     */
    @Override
    public void close() {
        clientMap.forEach((leaseId, client) -> {
            try {
                client.close();
            } catch (Exception ignored) {}
        });
        clientMap.clear();
        LOG.info("已關閉所有 MongoDB 連線");
    }

    /** 依動態憑證建立 MongoDB 連線字串。 */
    private String buildConnectionString(DynamicCredential cred) {
        return String.format(
                "mongodb://%s:%s@%s:%d/%s?authSource=admin&connectTimeoutMS=5000&serverSelectionTimeoutMS=5000",
                cred.getUsername(),
                cred.getPassword(),
                AppConfig.MONGO_HOST,
                AppConfig.MONGO_PORT,
                AppConfig.MONGO_DB_NAME
        );
    }
}
