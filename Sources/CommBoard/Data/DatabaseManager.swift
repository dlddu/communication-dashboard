import Foundation
import GRDB

/// Manages the SQLite database connection and schema migrations.
public final class DatabaseManager {
    private let dbQueue: DatabaseQueue

    public init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try migrate()
    }

    /// Initialises an in-memory database (useful for testing).
    public init() throws {
        dbQueue = try DatabaseQueue()
        try migrate()
    }

    // MARK: - Migration

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_notifications") { db in
            try db.create(table: "notifications") { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text).notNull()
                t.column("timestamp", .double).notNull()
                t.column("is_read", .boolean).notNull().defaults(to: false)
                t.column("metadata", .text).notNull().defaults(to: "{}")
                t.column("created_at", .double).notNull()
            }
        }

        migrator.registerMigration("v1_create_widget_layout") { db in
            try db.create(table: "widget_layout") { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .integer).notNull().defaults(to: 0)
                t.column("position_y", .integer).notNull().defaults(to: 0)
                t.column("size", .text).notNull().defaults(to: "medium")
                t.column("order", .integer).notNull().defaults(to: 0)
            }
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Notifications

    public func insertNotification(_ notification: AppNotification) throws {
        try dbQueue.write { db in
            try notification.insert(db)
        }
    }

    public func fetchAllNotifications() throws -> [AppNotification] {
        try dbQueue.read { db in
            try AppNotification.fetchAll(db)
        }
    }

    public func markNotificationRead(id: String) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE notifications SET is_read = 1 WHERE id = ?",
                arguments: [id]
            )
        }
    }

    // MARK: - Widget Layouts

    public func insertWidgetLayout(_ layout: WidgetLayout) throws {
        try dbQueue.write { db in
            try layout.insert(db)
        }
    }

    public func fetchAllWidgetLayouts() throws -> [WidgetLayout] {
        try dbQueue.read { db in
            try WidgetLayout.fetchAll(db)
        }
    }

    // MARK: - Schema Inspection (for tests)

    public func tableExists(_ name: String) throws -> Bool {
        try dbQueue.read { db in
            try db.tableExists(name)
        }
    }

    public func columnNames(in table: String) throws -> [String] {
        try dbQueue.read { db in
            try db.columns(in: table).map { $0.name }
        }
    }
}
