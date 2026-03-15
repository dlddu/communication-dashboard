import XCTest
@testable import CommBoard

// MARK: - DatabaseManagerTests
//
// DatabaseManager는 GRDB를 사용하여 SQLite DB를 관리합니다.
// 테스트에서는 in-memory DB를 사용합니다.
//
// 검증 대상 테이블:
//   - notifications: id, plugin_id, title, subtitle, body, timestamp, is_read, metadata(JSON), created_at
//   - widget_layout:  id, plugin_id, position_x, position_y, size, order

final class DatabaseManagerTests: XCTestCase {

    // MARK: - Properties

    var sut: DatabaseManager!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        // in-memory DB를 사용하여 각 테스트가 독립적인 상태에서 실행됩니다
        sut = try DatabaseManager(inMemory: true)
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_InMemory_Succeeds() throws {
        // Arrange & Act - setUp에서 이미 초기화됨

        // Assert
        XCTAssertNotNil(sut, "DatabaseManager는 in-memory 모드로 초기화되어야 합니다")
    }

    func testInitialization_FileBased_Succeeds() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let dbURL = tempDir.appendingPathComponent("test_commboard_\(UUID().uuidString).db")

        // Act
        let fileBasedManager = try DatabaseManager(path: dbURL.path)

        // Assert
        XCTAssertNotNil(fileBasedManager, "파일 기반 DatabaseManager가 생성되어야 합니다")

        // Cleanup
        try? FileManager.default.removeItem(at: dbURL)
    }

    // MARK: - Migration Tests

    func testMigration_CreatesNotificationsTable() throws {
        // Arrange & Act - 마이그레이션은 초기화 시 실행됨

        // Assert: notifications 테이블이 존재하는지 확인
        let tableExists = try sut.tableExists("notifications")
        XCTAssertTrue(tableExists, "마이그레이션 후 notifications 테이블이 존재해야 합니다")
    }

    func testMigration_CreatesWidgetLayoutTable() throws {
        // Arrange & Act - 마이그레이션은 초기화 시 실행됨

        // Assert: widget_layout 테이블이 존재하는지 확인
        let tableExists = try sut.tableExists("widget_layout")
        XCTAssertTrue(tableExists, "마이그레이션 후 widget_layout 테이블이 존재해야 합니다")
    }

    func testMigration_NotificationsTable_HasRequiredColumns() throws {
        // Arrange
        let expectedColumns = ["id", "plugin_id", "title", "subtitle", "body",
                               "timestamp", "is_read", "metadata", "created_at"]

        // Act
        let columns = try sut.columnNames(for: "notifications")

        // Assert
        for column in expectedColumns {
            XCTAssertTrue(
                columns.contains(column),
                "notifications 테이블에 '\(column)' 컬럼이 있어야 합니다"
            )
        }
    }

    func testMigration_WidgetLayoutTable_HasRequiredColumns() throws {
        // Arrange
        let expectedColumns = ["id", "plugin_id", "position_x", "position_y", "size", "order"]

        // Act
        let columns = try sut.columnNames(for: "widget_layout")

        // Assert
        for column in expectedColumns {
            XCTAssertTrue(
                columns.contains(column),
                "widget_layout 테이블에 '\(column)' 컬럼이 있어야 합니다"
            )
        }
    }

    // MARK: - Notification CRUD Tests

    func testInsertNotification_Succeeds() throws {
        // Arrange
        let notification = AppNotification(
            pluginId: "test-plugin",
            title: "Test Title",
            subtitle: "Test Subtitle",
            body: "Test Body",
            timestamp: Date(),
            isRead: false,
            metadata: ["key": "value"]
        )

        // Act
        let insertedId = try sut.insertNotification(notification)

        // Assert
        XCTAssertNotNil(insertedId, "알림 삽입 후 ID가 반환되어야 합니다")
    }

    func testFetchNotifications_ReturnsInsertedNotification() throws {
        // Arrange
        let notification = AppNotification(
            pluginId: "test-plugin",
            title: "Fetch Test",
            subtitle: nil,
            body: "Body content",
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )
        _ = try sut.insertNotification(notification)

        // Act
        let notifications = try sut.fetchNotifications()

        // Assert
        XCTAssertEqual(notifications.count, 1, "삽입된 알림 1개가 조회되어야 합니다")
        XCTAssertEqual(notifications.first?.title, "Fetch Test")
        XCTAssertEqual(notifications.first?.pluginId, "test-plugin")
    }

    func testFetchNotifications_ByPluginId_ReturnsFilteredResults() throws {
        // Arrange
        let notification1 = AppNotification(
            pluginId: "plugin-a",
            title: "From Plugin A",
            subtitle: nil,
            body: "body",
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )
        let notification2 = AppNotification(
            pluginId: "plugin-b",
            title: "From Plugin B",
            subtitle: nil,
            body: "body",
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )
        _ = try sut.insertNotification(notification1)
        _ = try sut.insertNotification(notification2)

        // Act
        let notifications = try sut.fetchNotifications(pluginId: "plugin-a")

        // Assert
        XCTAssertEqual(notifications.count, 1, "plugin-a의 알림만 조회되어야 합니다")
        XCTAssertEqual(notifications.first?.pluginId, "plugin-a")
    }

    func testUpdateNotification_IsRead_Succeeds() throws {
        // Arrange
        let notification = AppNotification(
            pluginId: "test-plugin",
            title: "Unread",
            subtitle: nil,
            body: "body",
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )
        let id = try sut.insertNotification(notification)

        // Act
        try sut.markNotificationAsRead(id: id)

        // Assert
        let updated = try sut.fetchNotification(id: id)
        XCTAssertTrue(updated?.isRead == true, "알림이 읽음 상태로 업데이트되어야 합니다")
    }

    func testDeleteNotification_Succeeds() throws {
        // Arrange
        let notification = AppNotification(
            pluginId: "test-plugin",
            title: "To Delete",
            subtitle: nil,
            body: "body",
            timestamp: Date(),
            isRead: false,
            metadata: nil
        )
        let id = try sut.insertNotification(notification)

        // Act
        try sut.deleteNotification(id: id)

        // Assert
        let notifications = try sut.fetchNotifications()
        XCTAssertEqual(notifications.count, 0, "삭제 후 알림 목록이 비어야 합니다")
    }

    func testNotification_MetadataJSON_PreservedOnRoundTrip() throws {
        // Arrange
        let metadata: [String: String] = ["key1": "value1", "key2": "value2"]
        let notification = AppNotification(
            pluginId: "test-plugin",
            title: "Metadata Test",
            subtitle: nil,
            body: "body",
            timestamp: Date(),
            isRead: false,
            metadata: metadata
        )

        // Act
        let id = try sut.insertNotification(notification)
        let fetched = try sut.fetchNotification(id: id)

        // Assert
        XCTAssertEqual(fetched?.metadata?["key1"], "value1", "metadata JSON이 보존되어야 합니다")
        XCTAssertEqual(fetched?.metadata?["key2"], "value2", "metadata JSON이 보존되어야 합니다")
    }

    // MARK: - WidgetLayout CRUD Tests

    func testInsertWidgetLayout_Succeeds() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 100.0,
            positionY: 200.0,
            size: "medium",
            order: 0
        )

        // Act
        let insertedId = try sut.insertWidgetLayout(layout)

        // Assert
        XCTAssertNotNil(insertedId, "위젯 레이아웃 삽입 후 ID가 반환되어야 합니다")
    }

    func testFetchWidgetLayouts_ReturnsInsertedLayout() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 50.0,
            positionY: 75.0,
            size: "large",
            order: 1
        )
        _ = try sut.insertWidgetLayout(layout)

        // Act
        let layouts = try sut.fetchWidgetLayouts()

        // Assert
        XCTAssertEqual(layouts.count, 1, "삽입된 레이아웃 1개가 조회되어야 합니다")
        XCTAssertEqual(layouts.first?.pluginId, "test-plugin")
        XCTAssertEqual(layouts.first?.positionX, 50.0, accuracy: 0.001)
        XCTAssertEqual(layouts.first?.positionY, 75.0, accuracy: 0.001)
    }

    func testUpdateWidgetLayout_Position_Succeeds() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0.0,
            positionY: 0.0,
            size: "small",
            order: 0
        )
        let id = try sut.insertWidgetLayout(layout)

        // Act
        try sut.updateWidgetLayout(id: id, positionX: 300.0, positionY: 400.0)

        // Assert
        let updated = try sut.fetchWidgetLayout(id: id)
        XCTAssertEqual(updated?.positionX, 300.0, accuracy: 0.001, "positionX가 업데이트되어야 합니다")
        XCTAssertEqual(updated?.positionY, 400.0, accuracy: 0.001, "positionY가 업데이트되어야 합니다")
    }

    func testDeleteWidgetLayout_Succeeds() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0.0,
            positionY: 0.0,
            size: "small",
            order: 0
        )
        let id = try sut.insertWidgetLayout(layout)

        // Act
        try sut.deleteWidgetLayout(id: id)

        // Assert
        let layouts = try sut.fetchWidgetLayouts()
        XCTAssertEqual(layouts.count, 0, "삭제 후 레이아웃 목록이 비어야 합니다")
    }

    func testFetchWidgetLayouts_OrderedByOrder() throws {
        // Arrange
        let layouts = [
            WidgetLayout(pluginId: "plugin-c", positionX: 0, positionY: 0, size: "small", order: 2),
            WidgetLayout(pluginId: "plugin-a", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(pluginId: "plugin-b", positionX: 0, positionY: 0, size: "small", order: 1),
        ]
        for layout in layouts {
            _ = try sut.insertWidgetLayout(layout)
        }

        // Act
        let fetched = try sut.fetchWidgetLayouts()

        // Assert
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched[0].order, 0, "order 컬럼 기준으로 정렬되어야 합니다")
        XCTAssertEqual(fetched[1].order, 1)
        XCTAssertEqual(fetched[2].order, 2)
    }
}
