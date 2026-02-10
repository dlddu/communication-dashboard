import XCTest
import GRDB
@testable import CommunicationDashboard

/// End-to-End Integration Tests
/// These tests verify that all components work together correctly using mocks
final class IntegrationTests: XCTestCase {
    var databaseManager: DatabaseManager!
    var configService: ConfigService!
    var fixtureLoader: FixtureLoader!
    var mockHTTPClient: MockHTTPClient!
    var mockShellExecutor: MockShellExecutor!
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Setup temporary directory
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        // Initialize services with test dependencies
        databaseManager = DatabaseManager(inMemory: true)
        try databaseManager.initialize()

        configService = ConfigService(baseDirectory: tempDirectory)
        try configService.initialize()

        // Initialize mocks
        let testBundle = Bundle(for: type(of: self))
        let fixturesPath = testBundle.resourcePath?
            .appending("/Fixtures") ?? ""
        fixtureLoader = FixtureLoader(fixturesDirectory: fixturesPath)

        mockHTTPClient = MockHTTPClient()
        mockShellExecutor = MockShellExecutor()

        // Configure mocks with fixture data
        try await setupMocks()
    }

    override func tearDown() async throws {
        // Cleanup
        databaseManager = nil
        configService = nil
        fixtureLoader = nil
        mockHTTPClient = nil
        mockShellExecutor = nil

        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        try await super.tearDown()
    }

    // MARK: - Setup Helpers

    private func setupMocks() async throws {
        // Load fixture data
        let slackFixture = try fixtureLoader.loadRaw(filename: "slack_messages.json")
        let gmailFixture = try fixtureLoader.loadRaw(filename: "gmail_messages.json")
        let linearFixture = try fixtureLoader.loadRaw(filename: "linear_issues.json")
        let githubFixture = try fixtureLoader.loadRaw(filename: "github_notifications.json")

        // Configure HTTP client
        mockHTTPClient.registerResponse(
            for: "https://slack.com/api/conversations.history",
            response: slackFixture
        )
        mockHTTPClient.registerResponse(
            for: "https://www.googleapis.com/gmail/v1/messages",
            response: gmailFixture
        )
        mockHTTPClient.registerResponse(
            for: "https://api.linear.app/graphql",
            response: linearFixture
        )
        mockHTTPClient.registerResponse(
            for: "https://api.github.com/notifications",
            response: githubFixture
        )

        // Configure shell executor for calendar
        let calendarFixture = try fixtureLoader.loadRaw(filename: "calendar_events.json")
        mockShellExecutor.registerOutput(
            for: "python3 scripts/fetch_calendar.py",
            output: calendarFixture
        )
    }

    // MARK: - Full Integration Tests

    func testFullDataIngestionPipeline() async throws {
        // Arrange
        let app = CommunicationDashboardApp(
            database: databaseManager,
            config: configService,
            httpClient: mockHTTPClient,
            shellExecutor: mockShellExecutor
        )

        // Act
        try await app.refreshAllPlugins()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        let itemCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }

        XCTAssertGreaterThan(itemCount ?? 0, 0, "Should have ingested items from all plugins")
    }

    func testSlackPluginIntegration() async throws {
        // Arrange
        let slackPlugin = SlackPlugin(httpClient: mockHTTPClient)

        // Act
        let messages = try await slackPlugin.fetchMessages()

        // Assert
        XCTAssertFalse(messages.isEmpty, "Should fetch Slack messages")

        // Verify data structure
        guard let firstMessage = messages.first else {
            XCTFail("Should have at least one message")
            return
        }

        XCTAssertNotNil(firstMessage.id, "Message should have ID")
        XCTAssertNotNil(firstMessage.text, "Message should have text")
    }

    func testGmailPluginIntegration() async throws {
        // Arrange
        let gmailPlugin = GmailPlugin(httpClient: mockHTTPClient)

        // Act
        let messages = try await gmailPlugin.fetchMessages()

        // Assert
        XCTAssertFalse(messages.isEmpty, "Should fetch Gmail messages")

        // Verify email format
        for message in messages {
            XCTAssertTrue(message.from.contains("@"), "Should have valid email address")
        }
    }

    func testLinearPluginIntegration() async throws {
        // Arrange
        let linearPlugin = LinearPlugin(httpClient: mockHTTPClient)

        // Act
        let issues = try await linearPlugin.fetchIssues()

        // Assert
        XCTAssertFalse(issues.isEmpty, "Should fetch Linear issues")

        // Verify issue states
        let validStates = ["todo", "in_progress", "done", "canceled"]
        for issue in issues {
            XCTAssertTrue(validStates.contains(issue.state), "Issue should have valid state")
        }
    }

    func testGitHubPluginIntegration() async throws {
        // Arrange
        let githubPlugin = GitHubPlugin(httpClient: mockHTTPClient)

        // Act
        let notifications = try await githubPlugin.fetchNotifications()

        // Assert
        XCTAssertFalse(notifications.isEmpty, "Should fetch GitHub notifications")

        // Verify notification structure
        for notification in notifications {
            XCTAssertNotNil(notification.repository, "Notification should have repository")
        }
    }

    func testCalendarPluginIntegration() async throws {
        // Arrange
        let calendarPlugin = CalendarPlugin(shellExecutor: mockShellExecutor)

        // Act
        let events = try await calendarPlugin.fetchEvents()

        // Assert
        XCTAssertFalse(events.isEmpty, "Should fetch calendar events")

        // Verify date ranges
        for event in events {
            XCTAssertLessThanOrEqual(
                event.startTime,
                event.endTime,
                "Event start should be before end"
            )
        }
    }

    func testDataPersistenceAcrossPlugins() async throws {
        // Arrange
        let slackPlugin = SlackPlugin(httpClient: mockHTTPClient)
        let gmailPlugin = GmailPlugin(httpClient: mockHTTPClient)
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act
        let slackMessages = try await slackPlugin.fetchMessages()
        let gmailMessages = try await gmailPlugin.fetchMessages()

        // Persist to database
        try dbQueue.write { db in
            for message in slackMessages {
                try db.execute(
                    sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                    arguments: [message.text, "slack:\(message.id)", Date(), Date()]
                )
            }

            for message in gmailMessages {
                try db.execute(
                    sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                    arguments: [message.subject, "gmail:\(message.id)", Date(), Date()]
                )
            }
        }

        // Assert
        let totalCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }

        XCTAssertEqual(
            totalCount,
            slackMessages.count + gmailMessages.count,
            "Should persist all messages to database"
        )
    }

    func testFullTextSearchAcrossAllPluginData() async throws {
        // Arrange
        let app = CommunicationDashboardApp(
            database: databaseManager,
            config: configService,
            httpClient: mockHTTPClient,
            shellExecutor: mockShellExecutor
        )
        try await app.refreshAllPlugins()

        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act
        let searchResults = try dbQueue.read { db in
            try Row.fetchAll(db, sql: "SELECT * FROM items_fts WHERE items_fts MATCH 'meeting'")
        }

        // Assert
        XCTAssertGreaterThan(searchResults.count, 0, "Should find items matching search term")
    }

    func testConfigurationLoading() async throws {
        // Arrange
        let config: ConfigFixture = try fixtureLoader.loadYAML(filename: "config.yaml")

        // Assert
        XCTAssertEqual(config.plugins.count, 5, "Should load all 5 plugin configurations")
        XCTAssertTrue(config.plugins.allSatisfy { $0.enabled }, "All test plugins should be enabled")
    }

    func testPluginDependencyInjection() async throws {
        // Arrange - Create plugins with injected dependencies
        let slackPlugin = SlackPlugin(httpClient: mockHTTPClient)
        let calendarPlugin = CalendarPlugin(shellExecutor: mockShellExecutor)

        // Act - Both should work with their respective mocks
        let slackMessages = try await slackPlugin.fetchMessages()
        let calendarEvents = try await calendarPlugin.fetchEvents()

        // Assert
        XCTAssertFalse(slackMessages.isEmpty, "Slack plugin should work with HTTP mock")
        XCTAssertFalse(calendarEvents.isEmpty, "Calendar plugin should work with shell mock")
    }

    // MARK: - Error Handling Integration Tests

    func testHandlePluginFailureGracefully() async throws {
        // Arrange
        mockHTTPClient.registerError(
            for: "https://slack.com/api/conversations.history",
            error: HTTPClientError.networkError("Connection timeout")
        )

        let slackPlugin = SlackPlugin(httpClient: mockHTTPClient)

        // Act & Assert
        do {
            _ = try await slackPlugin.fetchMessages()
            XCTFail("Should propagate plugin error")
        } catch {
            XCTAssertTrue(error is HTTPClientError, "Should handle HTTP client errors")
        }
    }

    func testHandleShellCommandFailureGracefully() async throws {
        // Arrange
        mockShellExecutor.registerError(
            for: "python3 scripts/fetch_calendar.py",
            error: ShellExecutorError.commandFailed(exitCode: 1, stderr: "Script error")
        )

        let calendarPlugin = CalendarPlugin(shellExecutor: mockShellExecutor)

        // Act & Assert
        do {
            _ = try await calendarPlugin.fetchEvents()
            XCTFail("Should propagate shell error")
        } catch {
            XCTAssertTrue(error is ShellExecutorError, "Should handle shell executor errors")
        }
    }

    func testDatabaseTransactionRollbackOnError() async throws {
        // Arrange
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act & Assert
        XCTAssertThrowsError(
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                    arguments: ["Test", "Content", Date(), Date()]
                )
                // Simulate error
                try db.execute(sql: "INVALID SQL")
            }
        )

        // Verify rollback
        let count = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }
        XCTAssertEqual(count, 0, "Should rollback on error")
    }

    // MARK: - Performance Tests

    func testBulkDataIngestionPerformance() async throws {
        // Arrange
        let app = CommunicationDashboardApp(
            database: databaseManager,
            config: configService,
            httpClient: mockHTTPClient,
            shellExecutor: mockShellExecutor
        )

        // Measure
        measure {
            do {
                try await app.refreshAllPlugins()
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }

    func testConcurrentPluginFetching() async throws {
        // Arrange
        let slackPlugin = SlackPlugin(httpClient: mockHTTPClient)
        let gmailPlugin = GmailPlugin(httpClient: mockHTTPClient)
        let linearPlugin = LinearPlugin(httpClient: mockHTTPClient)

        // Act - Fetch concurrently
        async let slackMessages = slackPlugin.fetchMessages()
        async let gmailMessages = gmailPlugin.fetchMessages()
        async let linearIssues = linearPlugin.fetchIssues()

        let results = try await (slackMessages, gmailMessages, linearIssues)

        // Assert
        XCTAssertFalse(results.0.isEmpty, "Should fetch Slack messages concurrently")
        XCTAssertFalse(results.1.isEmpty, "Should fetch Gmail messages concurrently")
        XCTAssertFalse(results.2.isEmpty, "Should fetch Linear issues concurrently")
    }
}
