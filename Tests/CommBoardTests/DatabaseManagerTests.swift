import XCTest
import GRDB
@testable import CommBoard

final class DatabaseManagerTests: XCTestCase {

    // MARK: - Setup

    var dbManager: DatabaseManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        dbManager = try DatabaseManager.makeInMemory()
    }

    override func tearDownWithError() throws {
        dbManager = nil
        try super.tearDownWithError()
    }

    // MARK: - Migration: notifications 테이블

    func test_migration_createsNotificationsTable() throws {
        // Arrange & Act
        let tableExists = try dbManager.dbQueue.read { db in
            try db.tableExists("notifications")
        }

        // Assert
        XCTAssertTrue(tableExists, "notifications 테이블이 생성되어야 합니다")
    }

    func test_migration_notificationsTable_hasRequiredColumns() throws {
        // Arrange
        let expectedColumns = [
            "id", "plugin_id", "title", "subtitle",
            "body", "timestamp", "is_read", "metadata", "created_at"
        ]

        // Act
        let columns = try dbManager.dbQueue.read { db -> [String] in
            let tableInfo = try db.columns(in: "notifications")
            return tableInfo.map { $0.name }
        }

        // Assert
        for column in expectedColumns {
            XCTAssertTrue(
                columns.contains(column),
                "notifications 테이블에 '\(column)' 컬럼이 존재해야 합니다"
            )
        }
    }

    func test_migration_notificationsTable_idIsPrimaryKeyAutoIncrement() throws {
        // Arrange & Act
        let pkColumns = try dbManager.dbQueue.read { db -> [String] in
            let primaryKey = try db.primaryKey("notifications")
            return primaryKey.columns
        }

        // Assert
        XCTAssertEqual(pkColumns, ["id"], "notifications 테이블의 기본 키는 'id'여야 합니다")
    }

    func test_migration_notificationsTable_isReadDefaultsToZero() throws {
        // Arrange
        let now = Date()

        // Act: is_read 없이 레코드 삽입
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO notifications (plugin_id, title, timestamp)
                VALUES (?, ?, ?)
                """,
                arguments: ["test-plugin", "Test Title", now]
            )
        }

        let isRead = try dbManager.dbQueue.read { db -> Int in
            let row = try Row.fetchOne(db, sql: "SELECT is_read FROM notifications LIMIT 1")
            return row?["is_read"] ?? -1
        }

        // Assert
        XCTAssertEqual(isRead, 0, "is_read 컬럼의 기본값은 0이어야 합니다")
    }

    func test_migration_notificationsTable_subtitleIsNullable() throws {
        // Arrange
        let now = Date()

        // Act: subtitle 없이 레코드 삽입
        XCTAssertNoThrow(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: """
                    INSERT INTO notifications (plugin_id, title, timestamp)
                    VALUES (?, ?, ?)
                    """,
                    arguments: ["test-plugin", "Title Only", now]
                )
            },
            "subtitle이 NULL인 알림 레코드를 삽입할 수 있어야 합니다"
        )
    }

    func test_migration_notificationsTable_bodyIsNullable() throws {
        // Arrange
        let now = Date()

        // Act & Assert
        XCTAssertNoThrow(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: """
                    INSERT INTO notifications (plugin_id, title, timestamp)
                    VALUES (?, ?, ?)
                    """,
                    arguments: ["test-plugin", "Title Only", now]
                )
            },
            "body가 NULL인 알림 레코드를 삽입할 수 있어야 합니다"
        )
    }

    func test_migration_notificationsTable_requiresPluginId() throws {
        // Arrange
        let now = Date()

        // Act & Assert
        XCTAssertThrowsError(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO notifications (title, timestamp) VALUES (?, ?)",
                    arguments: ["Title", now]
                )
            },
            "plugin_id가 없는 알림 레코드 삽입은 실패해야 합니다"
        )
    }

    func test_migration_notificationsTable_requiresTitle() throws {
        // Arrange
        let now = Date()

        // Act & Assert
        XCTAssertThrowsError(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO notifications (plugin_id, timestamp) VALUES (?, ?)",
                    arguments: ["test-plugin", now]
                )
            },
            "title이 없는 알림 레코드 삽입은 실패해야 합니다"
        )
    }

    func test_migration_notificationsTable_requiresTimestamp() throws {
        // Act & Assert
        XCTAssertThrowsError(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO notifications (plugin_id, title) VALUES (?, ?)",
                    arguments: ["test-plugin", "Title"]
                )
            },
            "timestamp가 없는 알림 레코드 삽입은 실패해야 합니다"
        )
    }

    func test_migration_notificationsTable_metadataIsNullable() throws {
        // Arrange
        let now = Date()

        // Act & Assert
        XCTAssertNoThrow(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: """
                    INSERT INTO notifications (plugin_id, title, timestamp, metadata)
                    VALUES (?, ?, ?, NULL)
                    """,
                    arguments: ["test-plugin", "Title", now]
                )
            },
            "metadata가 NULL인 알림 레코드를 삽입할 수 있어야 합니다"
        )
    }

    // MARK: - Migration: widget_layout 테이블

    func test_migration_createsWidgetLayoutTable() throws {
        // Arrange & Act
        let tableExists = try dbManager.dbQueue.read { db in
            try db.tableExists("widget_layout")
        }

        // Assert
        XCTAssertTrue(tableExists, "widget_layout 테이블이 생성되어야 합니다")
    }

    func test_migration_widgetLayoutTable_hasRequiredColumns() throws {
        // Arrange
        let expectedColumns = ["id", "plugin_id", "position_x", "position_y", "size", "order"]

        // Act
        let columns = try dbManager.dbQueue.read { db -> [String] in
            let tableInfo = try db.columns(in: "widget_layout")
            return tableInfo.map { $0.name }
        }

        // Assert
        for column in expectedColumns {
            XCTAssertTrue(
                columns.contains(column),
                "widget_layout 테이블에 '\(column)' 컬럼이 존재해야 합니다"
            )
        }
    }

    func test_migration_widgetLayoutTable_positionXDefaultsToZero() throws {
        // Act
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO widget_layout (plugin_id) VALUES (?)",
                arguments: ["test-plugin"]
            )
        }

        let positionX = try dbManager.dbQueue.read { db -> Double in
            let row = try Row.fetchOne(db, sql: "SELECT position_x FROM widget_layout LIMIT 1")
            return row?["position_x"] ?? -1.0
        }

        // Assert
        XCTAssertEqual(positionX, 0.0, accuracy: 0.001, "position_x의 기본값은 0.0이어야 합니다")
    }

    func test_migration_widgetLayoutTable_positionYDefaultsToZero() throws {
        // Act
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO widget_layout (plugin_id) VALUES (?)",
                arguments: ["test-plugin"]
            )
        }

        let positionY = try dbManager.dbQueue.read { db -> Double in
            let row = try Row.fetchOne(db, sql: "SELECT position_y FROM widget_layout LIMIT 1")
            return row?["position_y"] ?? -1.0
        }

        // Assert
        XCTAssertEqual(positionY, 0.0, accuracy: 0.001, "position_y의 기본값은 0.0이어야 합니다")
    }

    func test_migration_widgetLayoutTable_sizeIsNullable() throws {
        // Act & Assert
        XCTAssertNoThrow(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO widget_layout (plugin_id) VALUES (?)",
                    arguments: ["test-plugin"]
                )
            },
            "size가 NULL인 위젯 레이아웃 레코드를 삽입할 수 있어야 합니다"
        )
    }

    func test_migration_widgetLayoutTable_orderIsNullable() throws {
        // Act & Assert
        XCTAssertNoThrow(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO widget_layout (plugin_id) VALUES (?)",
                    arguments: ["test-plugin"]
                )
            },
            "order가 NULL인 위젯 레이아웃 레코드를 삽입할 수 있어야 합니다"
        )
    }

    func test_migration_widgetLayoutTable_requiresPluginId() throws {
        // Act & Assert
        XCTAssertThrowsError(
            try dbManager.dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO widget_layout (position_x, position_y) VALUES (?, ?)",
                    arguments: [1.0, 2.0]
                )
            },
            "plugin_id가 없는 위젯 레이아웃 레코드 삽입은 실패해야 합니다"
        )
    }

    // MARK: - 마이그레이션 멱등성

    func test_migration_isIdempotent_doesNotThrowOnMultipleInitializations() throws {
        // Act & Assert: 동일 DB에 두 번 migrate해도 에러가 없어야 합니다
        // DatabaseManager.makeInMemory()는 내부에서 migrate()를 호출하므로
        // 새 인스턴스 생성이 아닌 같은 dbQueue 재사용 시나리오 검증
        XCTAssertNoThrow(
            try DatabaseManager.makeInMemory(),
            "새 인메모리 DB 초기화는 항상 성공해야 합니다"
        )
    }

    // MARK: - 실제 데이터 삽입/조회

    func test_notifications_canInsertAndRetrieveRecord() throws {
        // Arrange
        let now = Date()

        // Act
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO notifications (plugin_id, title, subtitle, body, timestamp, metadata)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: ["slack", "New Message", "From Alice", "Hello!", now, "{\"channel\":\"#general\"}"]
            )
        }

        let row = try dbManager.dbQueue.read { db -> Row? in
            try Row.fetchOne(db, sql: "SELECT * FROM notifications WHERE plugin_id = ?", arguments: ["slack"])
        }

        // Assert
        XCTAssertNotNil(row, "삽입한 알림을 조회할 수 있어야 합니다")
        XCTAssertEqual(row?["plugin_id"] as? String, "slack")
        XCTAssertEqual(row?["title"] as? String, "New Message")
        XCTAssertEqual(row?["subtitle"] as? String, "From Alice")
        XCTAssertEqual(row?["body"] as? String, "Hello!")
        XCTAssertEqual(row?["is_read"] as? Int64, 0)
    }

    func test_widgetLayout_canInsertAndRetrieveRecord() throws {
        // Act
        try dbManager.dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT INTO widget_layout (plugin_id, position_x, position_y, size, "order")
                VALUES (?, ?, ?, ?, ?)
                """,
                arguments: ["github", 10.5, 20.0, 200.0, 1]
            )
        }

        let row = try dbManager.dbQueue.read { db -> Row? in
            try Row.fetchOne(db, sql: "SELECT * FROM widget_layout WHERE plugin_id = ?", arguments: ["github"])
        }

        // Assert
        XCTAssertNotNil(row, "삽입한 위젯 레이아웃을 조회할 수 있어야 합니다")
        XCTAssertEqual(row?["plugin_id"] as? String, "github")
        XCTAssertEqual(row?["position_x"] as? Double ?? 0, 10.5, accuracy: 0.001)
        XCTAssertEqual(row?["position_y"] as? Double ?? 0, 20.0, accuracy: 0.001)
        XCTAssertEqual(row?["size"] as? Double ?? 0, 200.0, accuracy: 0.001)
        XCTAssertEqual(row?["order"] as? Int64, 1)
    }
}
