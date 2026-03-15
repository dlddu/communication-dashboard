import Foundation
import GRDB

/// Represents a notification record stored in the database.
public struct Notification: Codable, FetchableRecord, PersistableRecord, Equatable {
    public static let databaseTableName = "notifications"

    public var id: String
    public var pluginId: String
    public var title: String
    public var subtitle: String?
    public var body: String
    public var timestamp: Double
    public var isRead: Bool
    public var metadata: String
    public var createdAt: Double

    public init(
        id: String = UUID().uuidString,
        pluginId: String,
        title: String,
        subtitle: String? = nil,
        body: String,
        timestamp: Double = Date().timeIntervalSince1970,
        isRead: Bool = false,
        metadata: String = "{}",
        createdAt: Double = Date().timeIntervalSince1970
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
