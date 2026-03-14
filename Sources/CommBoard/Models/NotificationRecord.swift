import Foundation
import GRDB

/// `notifications` 테이블과 매핑되는 레코드 모델입니다.
public struct NotificationRecord: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "notifications"

    public var id: String
    public var pluginId: String
    public var title: String
    public var subtitle: String?
    public var body: String?
    public var timestamp: Date
    public var isRead: Bool
    public var metadata: String?
    public var createdAt: Date

    public init(
        id: String,
        pluginId: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        timestamp: Date,
        isRead: Bool = false,
        metadata: String? = nil,
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

    enum CodingKeys: String, CodingKey {
        case id
        case pluginId = "plugin_id"
        case title
        case subtitle
        case body
        case timestamp
        case isRead = "is_read"
        case metadata
        case createdAt = "created_at"
    }
}
