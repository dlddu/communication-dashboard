import Foundation
import GRDB

// MARK: - Database Models

public struct NotificationRecord: Codable, FetchableRecord, PersistableRecord {
    public var id: String
    public var pluginId: String
    public var title: String
    public var subtitle: String?
    public var body: String?
    public var timestamp: Date
    public var isRead: Bool
    public var metadata: String?
    public var createdAt: Date

    public static var databaseTableName: String { "notifications" }

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

public struct WidgetLayout: Codable, FetchableRecord, PersistableRecord {
    public var id: String
    public var pluginId: String
    public var positionX: Int
    public var positionY: Int
    public var size: String
    public var order: Int

    public static var databaseTableName: String { "widget_layout" }

    enum CodingKeys: String, CodingKey {
        case id
        case pluginId = "plugin_id"
        case positionX = "position_x"
        case positionY = "position_y"
        case size
        case order
    }
}

// MARK: - DatabaseManager

public enum DatabaseManagerError: Error, LocalizedError {
    case initializationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let message):
            return "Database initialization failed: \(message)"
        }
    }
}

public class DatabaseManager {
    public private(set) var dbQueue: DatabaseQueue

    public init(path: String = ":memory:") throws {
        self.dbQueue = try DatabaseQueue(path: path)
        try self.runMigrations()
    }

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_notifications") { db in
            try db.create(table: "notifications") { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text)
                t.column("timestamp", .datetime).notNull()
                t.column("is_read", .boolean).notNull().defaults(to: false)
                t.column("metadata", .text)
                t.column("created_at", .datetime).notNull()
            }
        }

        migrator.registerMigration("v1_create_widget_layout") { db in
            try db.create(table: "widget_layout") { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .integer).notNull()
                t.column("position_y", .integer).notNull()
                t.column("size", .text).notNull()
                t.column("order", .integer).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }
}
