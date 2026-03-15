// DatabaseManager - SQLite DB schema initialization via GRDB migrations

import GRDB
import Foundation

// MARK: - Table definitions

struct NotificationRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "notifications"

    var id: Int64?
    var pluginId: String
    var title: String
    var subtitle: String?
    var body: String
    var timestamp: Date
    var isRead: Bool
    var metadata: String?  // JSON string
    var createdAt: Date

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

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

struct WidgetLayoutRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "widget_layout"

    var id: Int64?
    var pluginId: String
    var positionX: Double
    var positionY: Double
    var size: String
    var order: Int

    enum CodingKeys: String, CodingKey {
        case id
        case pluginId = "plugin_id"
        case positionX = "position_x"
        case positionY = "position_y"
        case size
        case order
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

// MARK: - DatabaseManager

class DatabaseManager {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrate()
    }

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_createNotificationsTable") { db in
            try db.create(table: "notifications", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("is_read", .boolean).notNull().defaults(to: false)
                t.column("metadata", .text)
                t.column("created_at", .datetime).notNull()
            }
        }

        migrator.registerMigration("v1_createWidgetLayoutTable") { db in
            try db.create(table: "widget_layout", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .double).notNull()
                t.column("position_y", .double).notNull()
                t.column("size", .text).notNull()
                t.column("order", .integer).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }
}
