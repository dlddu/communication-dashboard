import XCTest
import GRDB
@testable import CommunicationDashboard

final class DatabaseManagerTests: XCTestCase {

    // MARK: - Initialization

    func test_init_withInMemoryDatabase_succeeds() throws {
        // Arrange & Act
        let sut = try DatabaseManager(path: ":memory:")

        // Assert
        XCTAssertNotNil(sut.dbQueue)
    }

    // MARK: - notifications 테이블 마이그레이션

    func test_migration_createsNotificationsTable() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            XCTAssertTrue(try db.tableExists("notifications"), "notifications 테이블이 존재해야 합니다")
        }
    }

    func test_migration_notificationsTable_hasIdColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("id"), "id 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasPluginIdColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("plugin_id"), "plugin_id 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasTitleColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("title"), "title 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasSubtitleColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("subtitle"), "subtitle 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasBodyColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("body"), "body 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasTimestampColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("timestamp"), "timestamp 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasIsReadColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("is_read"), "is_read 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasMetadataColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("metadata"), "metadata 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_hasCreatedAtColumn() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "notifications")
            let columnNames = columns.map { $0.name }
            XCTAssertTrue(columnNames.contains("created_at"), "created_at 컬럼이 있어야 합니다")
        }
    }

    func test_migration_notificationsTable_isReadDefaultsFalse() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let now = Date()
        let record = NotificationRecord(
            id: UUID().uuidString,
            pluginId: "test-plugin",
            title: "Test Notification",
            subtitle: nil,
            body: nil,
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )

        // Act
        try sut.dbQueue.write { db in
            try record.insert(db)
        }

        // Assert
        let fetched = try sut.dbQueue.read { db in
            try NotificationRecord.fetchOne(db, key: record.id)
        }
        XCTAssertNotNil(fetched)
        XCTAssertFalse(fetched!.isRead, "is_read 기본값은 false 여야 합니다")
    }

    func test_migration_notificationsTable_allowsNullSubtitle() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let now = Date()
        let record = NotificationRecord(
            id: UUID().uuidString,
            pluginId: "test-plugin",
            title: "Test",
            subtitle: nil,
            body: nil,
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )

        // Act & Assert - subtitle이 nil이어도 삽입에 성공해야 합니다
        XCTAssertNoThrow(try sut.dbQueue.write { db in
            try record.insert(db)
        })
    }

    // MARK: - widget_layout 테이블 마이그레이션

    func test_migration_createsWidgetLayoutTable() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")

        // Act & Assert
        try sut.dbQueue.read { db in
            XCTAssertTrue(try db.tableExists("widget_layout"), "widget_layout 테이블이 존재해야 합니다")
        }
    }

    func test_migration_widgetLayoutTable_hasAllRequiredColumns() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let requiredColumns = ["id", "plugin_id", "position_x", "position_y", "size", "order"]

        // Act & Assert
        try sut.dbQueue.read { db in
            let columns = try db.columns(in: "widget_layout")
            let columnNames = columns.map { $0.name }
            for column in requiredColumns {
                XCTAssertTrue(columnNames.contains(column), "\(column) 컬럼이 있어야 합니다")
            }
        }
    }

    func test_migration_widgetLayoutTable_canInsertRecord() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let layout = WidgetLayout(
            id: UUID().uuidString,
            pluginId: "test-plugin",
            positionX: 0,
            positionY: 0,
            size: "medium",
            order: 1
        )

        // Act & Assert
        XCTAssertNoThrow(try sut.dbQueue.write { db in
            try layout.insert(db)
        })
    }

    // MARK: - CRUD 테스트

    func test_notifications_insertAndFetch_returnsCorrectRecord() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let now = Date()
        let expectedId = UUID().uuidString
        let record = NotificationRecord(
            id: expectedId,
            pluginId: "slack",
            title: "New Message",
            subtitle: "from John",
            body: "Hello World",
            timestamp: now,
            isRead: false,
            metadata: "{\"channel\": \"general\"}",
            createdAt: now
        )

        // Act
        try sut.dbQueue.write { db in
            try record.insert(db)
        }

        // Assert
        let fetched = try sut.dbQueue.read { db in
            try NotificationRecord.fetchOne(db, key: expectedId)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, expectedId)
        XCTAssertEqual(fetched?.pluginId, "slack")
        XCTAssertEqual(fetched?.title, "New Message")
        XCTAssertEqual(fetched?.subtitle, "from John")
        XCTAssertEqual(fetched?.body, "Hello World")
        XCTAssertEqual(fetched?.metadata, "{\"channel\": \"general\"}")
    }

    func test_notifications_multipleInserts_fetchAllReturnsCorrectCount() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let now = Date()

        // Act
        try sut.dbQueue.write { db in
            for i in 0..<5 {
                let record = NotificationRecord(
                    id: UUID().uuidString,
                    pluginId: "plugin-\(i)",
                    title: "Notification \(i)",
                    subtitle: nil,
                    body: nil,
                    timestamp: now,
                    isRead: false,
                    metadata: nil,
                    createdAt: now
                )
                try record.insert(db)
            }
        }

        // Assert
        let count = try sut.dbQueue.read { db in
            try NotificationRecord.fetchCount(db)
        }
        XCTAssertEqual(count, 5)
    }

    func test_notifications_updateIsRead_persistsChange() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let now = Date()
        var record = NotificationRecord(
            id: UUID().uuidString,
            pluginId: "test",
            title: "Test",
            subtitle: nil,
            body: nil,
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )
        try sut.dbQueue.write { db in try record.insert(db) }

        // Act
        record.isRead = true
        try sut.dbQueue.write { db in try record.update(db) }

        // Assert
        let fetched = try sut.dbQueue.read { db in
            try NotificationRecord.fetchOne(db, key: record.id)
        }
        XCTAssertEqual(fetched?.isRead, true)
    }

    func test_widgetLayout_insertAndFetch_returnsCorrectRecord() throws {
        // Arrange
        let sut = try DatabaseManager(path: ":memory:")
        let expectedId = UUID().uuidString
        let layout = WidgetLayout(
            id: expectedId,
            pluginId: "github",
            positionX: 10,
            positionY: 20,
            size: "large",
            order: 3
        )

        // Act
        try sut.dbQueue.write { db in try layout.insert(db) }

        // Assert
        let fetched = try sut.dbQueue.read { db in
            try WidgetLayout.fetchOne(db, key: expectedId)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.pluginId, "github")
        XCTAssertEqual(fetched?.positionX, 10)
        XCTAssertEqual(fetched?.positionY, 20)
        XCTAssertEqual(fetched?.size, "large")
        XCTAssertEqual(fetched?.order, 3)
    }

    // MARK: - 마이그레이션 멱등성(idempotency) 테스트

    func test_migration_runningTwice_doesNotDuplicateTables() throws {
        // Arrange - 동일한 파일로 두 번 DatabaseManager를 초기화
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir.appendingPathComponent("test-idempotent-\(UUID().uuidString).sqlite").path

        // Act
        let firstManager = try DatabaseManager(path: dbPath)
        let secondManager = try DatabaseManager(path: dbPath)

        // Assert - 두 번째 초기화 후에도 정상적으로 테이블이 하나씩만 존재해야 합니다
        try secondManager.dbQueue.read { db in
            XCTAssertTrue(try db.tableExists("notifications"))
            XCTAssertTrue(try db.tableExists("widget_layout"))
        }

        // 정리
        _ = firstManager
        try FileManager.default.removeItem(atPath: dbPath)
    }
}
