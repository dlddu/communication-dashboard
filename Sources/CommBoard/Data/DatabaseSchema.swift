import Foundation
import GRDB

/// SQLite 데이터베이스 스키마 초기화 및 마이그레이션을 담당합니다.
public struct DatabaseSchema {

    /// 주어진 DatabaseQueue에 전체 마이그레이션을 적용합니다.
    public static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "notifications", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text)
                t.column("timestamp", .datetime).notNull()
                t.column("is_read", .boolean).notNull().defaults(to: false)
                t.column("metadata", .text)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }

            try db.create(table: "widget_layout", ifNotExists: true) { t in
                t.column("id", .text).primaryKey()
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .integer).notNull().defaults(to: 0)
                    .check { $0 >= 0 }
                t.column("position_y", .integer).notNull().defaults(to: 0)
                    .check { $0 >= 0 }
                t.column("size", .text).notNull().defaults(to: WidgetLayout.defaultSize)
                    .check(sql: "size IN ('small', 'medium', 'large')")
                t.column("display_order", .integer).notNull().defaults(to: 0)
                    .check { $0 >= 0 }
            }
        }

        try migrator.migrate(dbQueue)
    }
}
