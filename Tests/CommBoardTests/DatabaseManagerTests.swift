import XCTest
import GRDB
@testable import CommBoard

final class DatabaseManagerTests: XCTestCase {

    // MARK: - Properties

    private var sut: DatabaseManager!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        // Use an in-memory database so each test starts with a clean state.
        sut = try DatabaseManager()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Schema: notifications table

    func test_notifications_table_exists_after_migration() throws {
        // Act
        let exists = try sut.tableExists("notifications")

        // Assert
        XCTAssertTrue(exists, "notifications table should exist after migration")
    }

    func test_notifications_table_has_all_required_columns() throws {
        // Arrange
        let expected: Set<String> = [
            "id", "plugin_id", "title", "subtitle", "body",
            "timestamp", "is_read", "metadata", "created_at"
        ]

        // Act
        let columns = Set(try sut.columnNames(in: "notifications"))

        // Assert
        XCTAssertEqual(
            columns,
            expected,
            "notifications table should have exactly the required columns"
        )
    }

    // MARK: - Schema: widget_layout table

    func test_widget_layout_table_exists_after_migration() throws {
        // Act
        let exists = try sut.tableExists("widget_layout")

        // Assert
        XCTAssertTrue(exists, "widget_layout table should exist after migration")
    }

    func test_widget_layout_table_has_all_required_columns() throws {
        // Arrange
        let expected: Set<String> = [
            "id", "plugin_id", "position_x", "position_y", "size", "order"
        ]

        // Act
        let columns = Set(try sut.columnNames(in: "widget_layout"))

        // Assert
        XCTAssertEqual(
            columns,
            expected,
            "widget_layout table should have exactly the required columns"
        )
    }

    // MARK: - Notifications CRUD: happy path

    func test_insert_notification_persists_record() throws {
        // Arrange
        let notification = AppNotification(
            id: "notif-001",
            pluginId: "slack",
            title: "New message",
            body: "Hello World",
            timestamp: 1_700_000_000,
            isRead: false,
            metadata: "{}",
            createdAt: 1_700_000_000
        )

        // Act
        try sut.insertNotification(notification)
        let fetched = try sut.fetchAllNotifications()

        // Assert
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first, notification)
    }

    func test_insert_multiple_notifications_all_persisted() throws {
        // Arrange
        let notifications = (1...3).map { i in
            AppNotification(
                id: "notif-\(i)",
                pluginId: "github",
                title: "PR #\(i)",
                body: "Body \(i)",
                timestamp: Double(i) * 1000
            )
        }

        // Act
        for n in notifications { try sut.insertNotification(n) }
        let fetched = try sut.fetchAllNotifications()

        // Assert
        XCTAssertEqual(fetched.count, 3)
    }

    func test_notification_optional_subtitle_stored_correctly() throws {
        // Arrange
        let withSubtitle = AppNotification(
            id: "with-sub",
            pluginId: "p1",
            title: "T",
            subtitle: "Subtitle value",
            body: "B"
        )
        let withoutSubtitle = AppNotification(
            id: "no-sub",
            pluginId: "p1",
            title: "T",
            subtitle: nil,
            body: "B"
        )

        // Act
        try sut.insertNotification(withSubtitle)
        try sut.insertNotification(withoutSubtitle)
        let fetched = try sut.fetchAllNotifications()

        // Assert
        let fetchedWith = fetched.first { $0.id == "with-sub" }
        let fetchedWithout = fetched.first { $0.id == "no-sub" }
        XCTAssertEqual(fetchedWith?.subtitle, "Subtitle value")
        XCTAssertNil(fetchedWithout?.subtitle)
    }

    func test_mark_notification_read_updates_is_read_flag() throws {
        // Arrange
        let notification = AppNotification(
            id: "notif-read",
            pluginId: "github",
            title: "Issue opened",
            body: "Body",
            isRead: false
        )
        try sut.insertNotification(notification)

        // Act
        try sut.markNotificationRead(id: "notif-read")
        let fetched = try sut.fetchAllNotifications()

        // Assert
        XCTAssertEqual(fetched.first?.isRead, true)
    }

    // MARK: - Notifications CRUD: edge cases

    func test_fetch_notifications_returns_empty_array_when_no_records() throws {
        // Act
        let fetched = try sut.fetchAllNotifications()

        // Assert
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_insert_notification_with_duplicate_id_throws() throws {
        // Arrange
        let notification = AppNotification(
            id: "dup-id",
            pluginId: "p1",
            title: "T",
            body: "B"
        )
        try sut.insertNotification(notification)

        // Act & Assert
        XCTAssertThrowsError(try sut.insertNotification(notification)) { error in
            // GRDB raises a DatabaseError for primary key constraint violations
            XCTAssertTrue(error is DatabaseError)
        }
    }

    // MARK: - Widget Layout CRUD: happy path

    func test_insert_widget_layout_persists_record() throws {
        // Arrange
        let layout = WidgetLayout(
            id: "layout-001",
            pluginId: "slack",
            positionX: 10,
            positionY: 20,
            size: "large",
            order: 1
        )

        // Act
        try sut.insertWidgetLayout(layout)
        let fetched = try sut.fetchAllWidgetLayouts()

        // Assert
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first, layout)
    }

    func test_insert_multiple_widget_layouts_all_persisted() throws {
        // Arrange
        let layouts = (1...4).map { i in
            WidgetLayout(
                id: "layout-\(i)",
                pluginId: "plugin-\(i)",
                positionX: i * 10,
                positionY: i * 5,
                order: i
            )
        }

        // Act
        for l in layouts { try sut.insertWidgetLayout(l) }
        let fetched = try sut.fetchAllWidgetLayouts()

        // Assert
        XCTAssertEqual(fetched.count, 4)
    }

    // MARK: - Widget Layout CRUD: edge cases

    func test_fetch_widget_layouts_returns_empty_array_when_no_records() throws {
        // Act
        let fetched = try sut.fetchAllWidgetLayouts()

        // Assert
        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - File-based DB

    func test_database_manager_creates_file_at_given_path() throws {
        // Arrange
        let tempDir = FileManager.default.temporaryDirectory
        let dbPath = tempDir
            .appendingPathComponent("test-\(UUID().uuidString).sqlite")
            .path

        // Act
        let fileManager = try DatabaseManager(path: dbPath)
        let exists = try fileManager.tableExists("notifications")

        // Assert
        XCTAssertTrue(exists, "DB file should be created at the given path with migrations applied")

        // Cleanup
        try? FileManager.default.removeItem(atPath: dbPath)
    }
}
