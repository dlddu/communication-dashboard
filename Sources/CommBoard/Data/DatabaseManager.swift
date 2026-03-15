import Foundation
import GRDB

/// SQLite 데이터베이스 스키마 및 마이그레이션을 관리합니다
public final class DatabaseManager {

    public let dbQueue: DatabaseQueue

    /// 인메모리 데이터베이스로 초기화 (테스트용)
    public static func makeInMemory() throws -> DatabaseManager {
        let queue = try DatabaseQueue()
        return try DatabaseManager(dbQueue: queue)
    }

    /// 파일 경로 기반 데이터베이스로 초기화
    public static func make(at path: String) throws -> DatabaseManager {
        let queue = try DatabaseQueue(path: path)
        return try DatabaseManager(dbQueue: queue)
    }

    private init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try migrate()
    }

    // MARK: - Migrations

    private func migrate() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_notifications") { db in
            try db.create(table: "notifications") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text)
                t.column("timestamp", .datetime).notNull()
                t.column("is_read", .integer).notNull().defaults(to: 0)
                t.column("metadata", .text)
                t.column("created_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
            }
        }

        migrator.registerMigration("v1_create_widget_layout") { db in
            try db.create(table: "widget_layout") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .real).notNull().defaults(to: 0)
                t.column("position_y", .real).notNull().defaults(to: 0)
                t.column("size", .real)
                t.column("order", .integer)
            }
        }

        try migrator.migrate(dbQueue)
    }
}
