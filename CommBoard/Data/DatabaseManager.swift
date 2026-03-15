import Foundation
import GRDB

/// SQLite 데이터베이스를 관리합니다. GRDB를 사용합니다.
final class DatabaseManager {

    // MARK: - Properties

    private let dbQueue: DatabaseQueue

    // MARK: - Init

    /// In-memory 데이터베이스로 초기화합니다 (주로 테스트용).
    init(inMemory: Bool) throws {
        dbQueue = try DatabaseQueue()
        try runMigrations()
    }

    /// 파일 기반 데이터베이스로 초기화합니다.
    init(path: String) throws {
        dbQueue = try DatabaseQueue(path: path)
        try runMigrations()
    }

    // MARK: - Migrations

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_create_notifications") { db in
            try db.create(table: "notifications") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("title", .text).notNull()
                t.column("subtitle", .text)
                t.column("body", .text).notNull()
                t.column("timestamp", .datetime).notNull()
                t.column("is_read", .boolean).notNull().defaults(to: false)
                t.column("metadata", .text)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
            }
        }

        migrator.registerMigration("v1_create_widget_layout") { db in
            try db.create(table: "widget_layout") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("plugin_id", .text).notNull()
                t.column("position_x", .double).notNull()
                t.column("position_y", .double).notNull()
                t.column("size", .text).notNull()
                t.column("order", .integer).notNull().defaults(to: 0)
            }
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Schema Inspection

    /// 테이블이 존재하는지 확인합니다.
    func tableExists(_ tableName: String) throws -> Bool {
        try dbQueue.read { db in
            try db.tableExists(tableName)
        }
    }

    /// 테이블의 컬럼 이름 목록을 반환합니다.
    func columnNames(for tableName: String) throws -> [String] {
        try dbQueue.read { db in
            let columns = try db.columns(in: tableName)
            return columns.map { $0.name }
        }
    }

    // MARK: - Notification CRUD

    /// 알림을 삽입하고 생성된 ID를 반환합니다.
    @discardableResult
    func insertNotification(_ notification: AppNotification) throws -> Int64 {
        var mutableNotification = notification
        try dbQueue.write { db in
            try mutableNotification.insert(db)
        }
        guard let id = mutableNotification.id else {
            throw DatabaseError(message: "알림 ID를 가져오지 못했습니다")
        }
        return id
    }

    /// 모든 알림을 조회합니다.
    func fetchNotifications() throws -> [AppNotification] {
        try dbQueue.read { db in
            try AppNotification.fetchAll(db)
        }
    }

    /// 특정 플러그인의 알림을 조회합니다.
    func fetchNotifications(pluginId: String) throws -> [AppNotification] {
        try dbQueue.read { db in
            try AppNotification
                .filter(Column("plugin_id") == pluginId)
                .fetchAll(db)
        }
    }

    /// ID로 특정 알림을 조회합니다.
    func fetchNotification(id: Int64) throws -> AppNotification? {
        try dbQueue.read { db in
            try AppNotification.fetchOne(db, key: id)
        }
    }

    /// 알림을 읽음 상태로 표시합니다.
    func markNotificationAsRead(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE notifications SET is_read = 1 WHERE id = ?",
                arguments: [id]
            )
        }
    }

    /// 알림을 삭제합니다.
    func deleteNotification(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM notifications WHERE id = ?",
                arguments: [id]
            )
        }
    }

    // MARK: - WidgetLayout CRUD

    /// 위젯 레이아웃을 삽입하고 생성된 ID를 반환합니다.
    @discardableResult
    func insertWidgetLayout(_ layout: WidgetLayout) throws -> Int64 {
        var mutableLayout = layout
        try dbQueue.write { db in
            try mutableLayout.insert(db)
        }
        guard let id = mutableLayout.id else {
            throw DatabaseError(message: "위젯 레이아웃 ID를 가져오지 못했습니다")
        }
        return id
    }

    /// 모든 위젯 레이아웃을 order 컬럼 기준으로 정렬하여 조회합니다.
    func fetchWidgetLayouts() throws -> [WidgetLayout] {
        try dbQueue.read { db in
            try WidgetLayout
                .order(Column("order"))
                .fetchAll(db)
        }
    }

    /// ID로 특정 위젯 레이아웃을 조회합니다.
    func fetchWidgetLayout(id: Int64) throws -> WidgetLayout? {
        try dbQueue.read { db in
            try WidgetLayout.fetchOne(db, key: id)
        }
    }

    /// 위젯 레이아웃의 위치를 업데이트합니다.
    func updateWidgetLayout(id: Int64, positionX: Double, positionY: Double) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE widget_layout SET position_x = ?, position_y = ? WHERE id = ?",
                arguments: [positionX, positionY, id]
            )
        }
    }

    /// 위젯 레이아웃을 삭제합니다.
    func deleteWidgetLayout(id: Int64) throws {
        try dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM widget_layout WHERE id = ?",
                arguments: [id]
            )
        }
    }
}

// MARK: - DatabaseError

struct DatabaseError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
