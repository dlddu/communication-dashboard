import XCTest
import GRDB
@testable import CommBoard

final class DatabaseSchemaTests: XCTestCase {

    // MARK: - Setup Helpers

    /// 인메모리 DatabaseQueue를 생성하고 마이그레이션을 적용합니다.
    private func makeMigratedDatabase() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue()
        try DatabaseSchema.migrate(dbQueue)
        return dbQueue
    }

    // MARK: - Migration Tests

    func test_migrate_doesNotThrow() throws {
        // Arrange & Act & Assert
        XCTAssertNoThrow(try makeMigratedDatabase())
    }

    func test_migrate_isIdempotent_whenCalledMultipleTimes() throws {
        // Arrange
        let dbQueue = try DatabaseQueue()

        // Act & Assert - 동일한 DB에 마이그레이션을 두 번 적용해도 오류 없음
        XCTAssertNoThrow(try DatabaseSchema.migrate(dbQueue))
        XCTAssertNoThrow(try DatabaseSchema.migrate(dbQueue))
    }

    // MARK: - notifications 테이블 존재 확인

    func test_notificationsTable_exists_afterMigration() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let tableExists = try dbQueue.read { db in
            try db.tableExists("notifications")
        }

        // Assert
        XCTAssertTrue(tableExists)
    }

    // MARK: - notifications 테이블 컬럼 확인

    func test_notificationsTable_hasColumn_id_asTextPrimaryKey() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let idColumn = columns.first { $0.name == "id" }

        // Assert
        XCTAssertNotNil(idColumn, "id 컬럼이 존재해야 합니다")
        XCTAssertEqual(idColumn?.type.uppercased(), "TEXT")
    }

    func test_notificationsTable_hasColumn_pluginId_notNull() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "plugin_id" }

        // Assert
        XCTAssertNotNil(column, "plugin_id 컬럼이 존재해야 합니다")
        XCTAssertEqual(column?.type.uppercased(), "TEXT")
        XCTAssertTrue(column?.isNotNull ?? false, "plugin_id는 NOT NULL이어야 합니다")
    }

    func test_notificationsTable_hasColumn_title_notNull() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "title" }

        // Assert
        XCTAssertNotNil(column, "title 컬럼이 존재해야 합니다")
        XCTAssertEqual(column?.type.uppercased(), "TEXT")
        XCTAssertTrue(column?.isNotNull ?? false, "title은 NOT NULL이어야 합니다")
    }

    func test_notificationsTable_hasColumn_subtitle_nullable() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "subtitle" }

        // Assert
        XCTAssertNotNil(column, "subtitle 컬럼이 존재해야 합니다")
        XCTAssertFalse(column?.isNotNull ?? true, "subtitle은 nullable이어야 합니다")
    }

    func test_notificationsTable_hasColumn_body_nullable() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "body" }

        // Assert
        XCTAssertNotNil(column, "body 컬럼이 존재해야 합니다")
        XCTAssertFalse(column?.isNotNull ?? true, "body는 nullable이어야 합니다")
    }

    func test_notificationsTable_hasColumn_timestamp_notNull() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "timestamp" }

        // Assert
        XCTAssertNotNil(column, "timestamp 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "timestamp는 NOT NULL이어야 합니다")
    }

    func test_notificationsTable_hasColumn_isRead_notNull_withDefaultFalse() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "is_read" }

        // Assert
        XCTAssertNotNil(column, "is_read 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "is_read는 NOT NULL이어야 합니다")
        // 기본값 0 (false) 확인
        XCTAssertEqual(column?.defaultValueSQL, "0")
    }

    func test_notificationsTable_hasColumn_metadata_nullable() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "metadata" }

        // Assert
        XCTAssertNotNil(column, "metadata 컬럼이 존재해야 합니다")
        XCTAssertFalse(column?.isNotNull ?? true, "metadata는 nullable이어야 합니다")
    }

    func test_notificationsTable_hasColumn_createdAt_notNull_withDefaultCurrentTimestamp() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let column = columns.first { $0.name == "created_at" }

        // Assert
        XCTAssertNotNil(column, "created_at 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "created_at는 NOT NULL이어야 합니다")
        XCTAssertNotNil(column?.defaultValueSQL, "created_at는 기본값(CURRENT_TIMESTAMP)이 있어야 합니다")
    }

    func test_notificationsTable_hasAllNineColumns() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()
        let expectedColumns = Set(["id", "plugin_id", "title", "subtitle", "body",
                                   "timestamp", "is_read", "metadata", "created_at"])

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let actualColumns = Set(columns.map { $0.name })

        // Assert
        XCTAssertEqual(actualColumns, expectedColumns)
    }

    // MARK: - widget_layout 테이블 존재 확인

    func test_widgetLayoutTable_exists_afterMigration() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let tableExists = try dbQueue.read { db in
            try db.tableExists("widget_layout")
        }

        // Assert
        XCTAssertTrue(tableExists)
    }

    // MARK: - widget_layout 테이블 컬럼 확인

    func test_widgetLayoutTable_hasColumn_id_asTextPrimaryKey() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "id" }

        // Assert
        XCTAssertNotNil(column, "id 컬럼이 존재해야 합니다")
        XCTAssertEqual(column?.type.uppercased(), "TEXT")
    }

    func test_widgetLayoutTable_hasColumn_pluginId_notNull() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "plugin_id" }

        // Assert
        XCTAssertNotNil(column, "plugin_id 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "plugin_id는 NOT NULL이어야 합니다")
    }

    func test_widgetLayoutTable_hasColumn_positionX_notNull_withDefaultZero() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "position_x" }

        // Assert
        XCTAssertNotNil(column, "position_x 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "position_x는 NOT NULL이어야 합니다")
        XCTAssertEqual(column?.defaultValueSQL, "0")
    }

    func test_widgetLayoutTable_hasColumn_positionY_notNull_withDefaultZero() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "position_y" }

        // Assert
        XCTAssertNotNil(column, "position_y 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "position_y는 NOT NULL이어야 합니다")
        XCTAssertEqual(column?.defaultValueSQL, "0")
    }

    func test_widgetLayoutTable_hasColumn_size_notNull_withDefaultMedium() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "size" }

        // Assert
        XCTAssertNotNil(column, "size 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "size는 NOT NULL이어야 합니다")
        XCTAssertEqual(column?.defaultValueSQL, "'medium'")
    }

    func test_widgetLayoutTable_hasColumn_displayOrder_notNull_withDefaultZero() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let column = columns.first { $0.name == "display_order" }

        // Assert
        XCTAssertNotNil(column, "display_order 컬럼이 존재해야 합니다")
        XCTAssertTrue(column?.isNotNull ?? false, "display_order는 NOT NULL이어야 합니다")
        XCTAssertEqual(column?.defaultValueSQL, "0")
    }

    func test_widgetLayoutTable_hasAllSixColumns() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()
        let expectedColumns = Set(["id", "plugin_id", "position_x", "position_y",
                                   "size", "display_order"])

        // Act
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let actualColumns = Set(columns.map { $0.name })

        // Assert
        XCTAssertEqual(actualColumns, expectedColumns)
    }

    // MARK: - CRUD 기본 동작 확인

    func test_notifications_canInsertAndFetch_record() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()
        let record = NotificationRecord(
            id: "test-001",
            pluginId: "slack",
            title: "새 메시지",
            subtitle: "채널 #general",
            body: "안녕하세요",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            isRead: false,
            metadata: "{\"channel\": \"#general\"}"
        )

        // Act
        try dbQueue.write { db in
            try record.insert(db)
        }
        let fetched = try dbQueue.read { db in
            try NotificationRecord.fetchOne(db, key: "test-001")
        }

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, "test-001")
        XCTAssertEqual(fetched?.pluginId, "slack")
        XCTAssertEqual(fetched?.title, "새 메시지")
        XCTAssertEqual(fetched?.isRead, false)
    }

    func test_widgetLayout_canInsertAndFetch_record() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()
        let record = WidgetLayout(
            id: "widget-001",
            pluginId: "slack",
            positionX: 10,
            positionY: 20,
            size: "large",
            displayOrder: 1
        )

        // Act
        try dbQueue.write { db in
            try record.insert(db)
        }
        let fetched = try dbQueue.read { db in
            try WidgetLayout.fetchOne(db, key: "widget-001")
        }

        // Assert
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, "widget-001")
        XCTAssertEqual(fetched?.positionX, 10)
        XCTAssertEqual(fetched?.positionY, 20)
        XCTAssertEqual(fetched?.size, "large")
        XCTAssertEqual(fetched?.displayOrder, 1)
    }

    func test_notifications_isRead_defaultsToFalse_whenNotSpecified() throws {
        // Arrange
        let dbQueue = try makeMigratedDatabase()

        // Act - is_read 없이 raw SQL로 삽입
        try dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO notifications (id, plugin_id, title, timestamp)
                VALUES (?, ?, ?, ?)
                """,
                arguments: ["raw-001", "github", "PR opened", "2024-01-01T00:00:00Z"]
            )
        }
        let isRead = try dbQueue.read { db -> Bool? in
            let row = try Row.fetchOne(db, sql: "SELECT is_read FROM notifications WHERE id = ?",
                                      arguments: ["raw-001"])
            return row?["is_read"]
        }

        // Assert
        XCTAssertEqual(isRead, false, "is_read의 기본값은 false(0)이어야 합니다")
    }
}
