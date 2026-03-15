import XCTest
import GRDB
@testable import CommBoard

final class DatabaseMigrationTests: XCTestCase {

    // MARK: - Setup / Teardown

    var dbQueue: DatabaseQueue!

    override func setUp() async throws {
        try await super.setUp()
        // Use in-memory database for all tests
        dbQueue = try DatabaseQueue()
    }

    override func tearDown() async throws {
        dbQueue = nil
        try await super.tearDown()
    }

    // MARK: - Schema Initialization

    func test_migration_createsNotificationsTable() throws {
        // Arrange & Act
        _ = try DatabaseManager(dbQueue: dbQueue)

        // Assert: table exists and has the expected columns
        let columns = try dbQueue.read { db in
            try db.columns(in: "notifications")
        }
        let columnNames = Set(columns.map { $0.name })

        XCTAssertTrue(columnNames.contains("id"), "notifications table must have 'id' column")
        XCTAssertTrue(columnNames.contains("plugin_id"), "notifications table must have 'plugin_id' column")
        XCTAssertTrue(columnNames.contains("title"), "notifications table must have 'title' column")
        XCTAssertTrue(columnNames.contains("subtitle"), "notifications table must have 'subtitle' column")
        XCTAssertTrue(columnNames.contains("body"), "notifications table must have 'body' column")
        XCTAssertTrue(columnNames.contains("timestamp"), "notifications table must have 'timestamp' column")
        XCTAssertTrue(columnNames.contains("is_read"), "notifications table must have 'is_read' column")
        XCTAssertTrue(columnNames.contains("metadata"), "notifications table must have 'metadata' column")
        XCTAssertTrue(columnNames.contains("created_at"), "notifications table must have 'created_at' column")
    }

    func test_migration_createsWidgetLayoutTable() throws {
        // Arrange & Act
        _ = try DatabaseManager(dbQueue: dbQueue)

        // Assert: table exists and has the expected columns
        let columns = try dbQueue.read { db in
            try db.columns(in: "widget_layout")
        }
        let columnNames = Set(columns.map { $0.name })

        XCTAssertTrue(columnNames.contains("id"), "widget_layout table must have 'id' column")
        XCTAssertTrue(columnNames.contains("plugin_id"), "widget_layout table must have 'plugin_id' column")
        XCTAssertTrue(columnNames.contains("position_x"), "widget_layout table must have 'position_x' column")
        XCTAssertTrue(columnNames.contains("position_y"), "widget_layout table must have 'position_y' column")
        XCTAssertTrue(columnNames.contains("size"), "widget_layout table must have 'size' column")
        XCTAssertTrue(columnNames.contains("order"), "widget_layout table must have 'order' column")
    }

    func test_migration_notificationsTable_idIsPrimaryKey() throws {
        // Arrange & Act
        _ = try DatabaseManager(dbQueue: dbQueue)

        // Assert: id column is the primary key
        let pkInfo = try dbQueue.read { db in
            try db.primaryKey("notifications")
        }

        XCTAssertEqual(pkInfo.columns, ["id"])
    }

    func test_migration_widgetLayoutTable_idIsPrimaryKey() throws {
        // Arrange & Act
        _ = try DatabaseManager(dbQueue: dbQueue)

        // Assert: id column is the primary key
        let pkInfo = try dbQueue.read { db in
            try db.primaryKey("widget_layout")
        }

        XCTAssertEqual(pkInfo.columns, ["id"])
    }

    func test_migration_isIdempotent_runningTwiceDoesNotThrow() throws {
        // Arrange: first migration
        _ = try DatabaseManager(dbQueue: dbQueue)

        // Act & Assert: second DatabaseManager on same db should not throw
        XCTAssertNoThrow(try DatabaseManager(dbQueue: dbQueue))
    }

    // MARK: - CRUD: notifications

    func test_notifications_insertAndFetch_roundtrip() throws {
        // Arrange
        _ = try DatabaseManager(dbQueue: dbQueue)
        let now = Date()
        var record = NotificationRecord(
            id: nil,
            pluginId: "slack",
            title: "New message",
            subtitle: "From #general",
            body: "Hello, world!",
            timestamp: now,
            isRead: false,
            metadata: "{\"channel\": \"general\"}",
            createdAt: now
        )

        // Act
        try dbQueue.write { db in
            try record.insert(db)
        }
        let fetched = try dbQueue.read { db in
            try NotificationRecord.fetchAll(db)
        }

        // Assert
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].pluginId, "slack")
        XCTAssertEqual(fetched[0].title, "New message")
        XCTAssertEqual(fetched[0].subtitle, "From #general")
        XCTAssertEqual(fetched[0].body, "Hello, world!")
        XCTAssertEqual(fetched[0].isRead, false)
        XCTAssertEqual(fetched[0].metadata, "{\"channel\": \"general\"}")
    }

    func test_notifications_subtitleIsNullable() throws {
        // Arrange
        _ = try DatabaseManager(dbQueue: dbQueue)
        let now = Date()
        var record = NotificationRecord(
            id: nil,
            pluginId: "github",
            title: "PR merged",
            subtitle: nil,
            body: "Your PR was merged.",
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )

        // Act
        try dbQueue.write { db in
            try record.insert(db)
        }
        let fetched = try dbQueue.read { db in
            try NotificationRecord.fetchAll(db)
        }

        // Assert
        XCTAssertNil(fetched[0].subtitle)
        XCTAssertNil(fetched[0].metadata)
    }

    func test_notifications_markAsRead() throws {
        // Arrange
        _ = try DatabaseManager(dbQueue: dbQueue)
        let now = Date()
        var record = NotificationRecord(
            id: nil,
            pluginId: "slack",
            title: "Unread",
            subtitle: nil,
            body: "Unread body",
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )
        try dbQueue.write { db in try record.insert(db) }

        // Act
        try dbQueue.write { db in
            try db.execute(sql: "UPDATE notifications SET is_read = 1 WHERE plugin_id = 'slack'")
        }
        let fetched = try dbQueue.read { db in
            try NotificationRecord.fetchAll(db)
        }

        // Assert
        XCTAssertTrue(fetched[0].isRead)
    }

    // MARK: - CRUD: widget_layout

    func test_widgetLayout_insertAndFetch_roundtrip() throws {
        // Arrange
        _ = try DatabaseManager(dbQueue: dbQueue)
        var record = WidgetLayoutRecord(
            id: nil,
            pluginId: "slack",
            positionX: 10.5,
            positionY: 20.0,
            size: "medium",
            order: 1
        )

        // Act
        try dbQueue.write { db in
            try record.insert(db)
        }
        let fetched = try dbQueue.read { db in
            try WidgetLayoutRecord.fetchAll(db)
        }

        // Assert
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].pluginId, "slack")
        XCTAssertEqual(fetched[0].positionX, 10.5)
        XCTAssertEqual(fetched[0].positionY, 20.0)
        XCTAssertEqual(fetched[0].size, "medium")
        XCTAssertEqual(fetched[0].order, 1)
    }

    func test_widgetLayout_updatePosition() throws {
        // Arrange
        _ = try DatabaseManager(dbQueue: dbQueue)
        var record = WidgetLayoutRecord(
            id: nil,
            pluginId: "github",
            positionX: 0,
            positionY: 0,
            size: "small",
            order: 2
        )
        try dbQueue.write { db in try record.insert(db) }

        // Act
        try dbQueue.write { db in
            try db.execute(
                sql: "UPDATE widget_layout SET position_x = 100.0, position_y = 200.0 WHERE plugin_id = 'github'"
            )
        }
        let fetched = try dbQueue.read { db in
            try WidgetLayoutRecord.fetchAll(db)
        }

        // Assert
        XCTAssertEqual(fetched[0].positionX, 100.0)
        XCTAssertEqual(fetched[0].positionY, 200.0)
    }
}
