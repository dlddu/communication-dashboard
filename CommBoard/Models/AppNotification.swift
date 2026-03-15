import Foundation
import GRDB

/// 앱 알림 모델. notifications 테이블과 매핑됩니다.
struct AppNotification: Codable, Equatable {

    // MARK: - Properties

    var id: Int64?
    var pluginId: String
    var title: String
    var subtitle: String?
    var body: String
    var timestamp: Date
    var isRead: Bool
    var metadata: [String: String]?
    var createdAt: Date

    // MARK: - Init

    init(
        id: Int64? = nil,
        pluginId: String,
        title: String,
        subtitle: String?,
        body: String,
        timestamp: Date,
        isRead: Bool,
        metadata: [String: String]?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.pluginId = pluginId
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.timestamp = timestamp
        self.isRead = isRead
        self.metadata = metadata
        self.createdAt = createdAt
    }
}

// MARK: - GRDB FetchableRecord

extension AppNotification: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        pluginId = row["plugin_id"]
        title = row["title"]
        subtitle = row["subtitle"]
        body = row["body"]
        timestamp = row["timestamp"]
        isRead = row["is_read"]
        createdAt = row["created_at"]

        // metadata는 JSON 문자열로 저장됩니다
        if let metadataJSON: String = row["metadata"] {
            let data = Data(metadataJSON.utf8)
            metadata = try? JSONDecoder().decode([String: String].self, from: data)
        } else {
            metadata = nil
        }
    }
}

// MARK: - GRDB MutablePersistableRecord

extension AppNotification: MutablePersistableRecord {
    static let databaseTableName = "notifications"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["plugin_id"] = pluginId
        container["title"] = title
        container["subtitle"] = subtitle
        container["body"] = body
        container["timestamp"] = timestamp
        container["is_read"] = isRead
        container["created_at"] = createdAt

        // metadata를 JSON 문자열로 인코딩
        if let metadata = metadata {
            let data = try JSONEncoder().encode(metadata)
            container["metadata"] = String(data: data, encoding: .utf8)
        } else {
            container["metadata"] = nil
        }
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
