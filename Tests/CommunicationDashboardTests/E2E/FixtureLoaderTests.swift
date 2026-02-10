import XCTest
import Foundation
@testable import CommunicationDashboard

/// Tests for FixtureLoader that loads test data from JSON and YAML files
/// This enables consistent test data management across E2E tests
final class FixtureLoaderTests: XCTestCase {
    var fixtureLoader: FixtureLoader!

    override func setUp() {
        super.setUp()
        // Initialize with test fixtures directory
        let testBundle = Bundle(for: type(of: self))
        let fixturesPath = testBundle.resourcePath?
            .appending("/Fixtures") ?? ""
        fixtureLoader = FixtureLoader(fixturesDirectory: fixturesPath)
    }

    override func tearDown() {
        fixtureLoader = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testLoadJSONFixtureReturnsDecodedData() throws {
        // Act
        let slackData: SlackMessagesFixture = try fixtureLoader.loadJSON(filename: "slack_messages.json")

        // Assert
        XCTAssertNotNil(slackData, "Should load and decode Slack messages fixture")
        XCTAssertFalse(slackData.messages.isEmpty, "Should contain message data")
    }

    func testLoadYAMLFixtureReturnsDecodedData() throws {
        // Act
        let config: ConfigFixture = try fixtureLoader.loadYAML(filename: "config.yaml")

        // Assert
        XCTAssertNotNil(config, "Should load and decode config fixture")
        XCTAssertFalse(config.plugins.isEmpty, "Should contain plugin configurations")
    }

    func testLoadRawJSONFixtureReturnsString() throws {
        // Act
        let rawJSON = try fixtureLoader.loadRaw(filename: "slack_messages.json")

        // Assert
        XCTAssertFalse(rawJSON.isEmpty, "Should return raw JSON string")
        XCTAssertTrue(rawJSON.contains("{"), "Should contain JSON content")
    }

    func testLoadAllPluginFixtures() throws {
        // Act
        let slackFixture: SlackMessagesFixture = try fixtureLoader.loadJSON(filename: "slack_messages.json")
        let gmailFixture: GmailMessagesFixture = try fixtureLoader.loadJSON(filename: "gmail_messages.json")
        let linearFixture: LinearIssuesFixture = try fixtureLoader.loadJSON(filename: "linear_issues.json")
        let githubFixture: GitHubNotificationsFixture = try fixtureLoader.loadJSON(filename: "github_notifications.json")
        let calendarFixture: CalendarEventsFixture = try fixtureLoader.loadJSON(filename: "calendar_events.json")

        // Assert
        XCTAssertNotNil(slackFixture, "Should load Slack fixture")
        XCTAssertNotNil(gmailFixture, "Should load Gmail fixture")
        XCTAssertNotNil(linearFixture, "Should load Linear fixture")
        XCTAssertNotNil(githubFixture, "Should load GitHub fixture")
        XCTAssertNotNil(calendarFixture, "Should load Calendar fixture")
    }

    func testFixtureDataContainsExpectedStructure() throws {
        // Act
        let slackData: SlackMessagesFixture = try fixtureLoader.loadJSON(filename: "slack_messages.json")

        // Assert
        guard let firstMessage = slackData.messages.first else {
            XCTFail("Should have at least one message")
            return
        }

        XCTAssertNotNil(firstMessage.id, "Message should have id")
        XCTAssertNotNil(firstMessage.text, "Message should have text")
        XCTAssertNotNil(firstMessage.user, "Message should have user")
        XCTAssertNotNil(firstMessage.timestamp, "Message should have timestamp")
    }

    func testConfigFixtureContainsPluginConfiguration() throws {
        // Act
        let config: ConfigFixture = try fixtureLoader.loadYAML(filename: "config.yaml")

        // Assert
        XCTAssertTrue(config.plugins.contains { $0.name == "slack" }, "Should contain Slack plugin")
        XCTAssertTrue(config.plugins.contains { $0.name == "gmail" }, "Should contain Gmail plugin")
        XCTAssertTrue(config.plugins.contains { $0.name == "linear" }, "Should contain Linear plugin")
        XCTAssertTrue(config.plugins.contains { $0.name == "github" }, "Should contain GitHub plugin")
        XCTAssertTrue(config.plugins.contains { $0.name == "calendar" }, "Should contain Calendar plugin")
    }

    // MARK: - Edge Case Tests

    func testLoadFixtureWithUTF8Characters() throws {
        // Act
        let slackData: SlackMessagesFixture = try fixtureLoader.loadJSON(filename: "slack_messages.json")

        // Assert
        let messagesWithEmoji = slackData.messages.filter { $0.text.contains("👍") || $0.text.contains("🎉") }
        XCTAssertFalse(messagesWithEmoji.isEmpty, "Should handle UTF-8 emoji characters")
    }

    func testLoadFixtureWithLargeDataset() throws {
        // Act
        let gmailData: GmailMessagesFixture = try fixtureLoader.loadJSON(filename: "gmail_messages.json")

        // Assert
        XCTAssertGreaterThan(gmailData.messages.count, 10, "Should handle large datasets")
    }

    func testLoadFixtureWithNestedObjects() throws {
        // Act
        let linearData: LinearIssuesFixture = try fixtureLoader.loadJSON(filename: "linear_issues.json")

        // Assert
        guard let firstIssue = linearData.issues.first else {
            XCTFail("Should have at least one issue")
            return
        }

        XCTAssertNotNil(firstIssue.assignee, "Should handle nested assignee object")
        XCTAssertNotNil(firstIssue.labels, "Should handle nested labels array")
    }

    func testLoadFixtureWithNullValues() throws {
        // Act
        let githubData: GitHubNotificationsFixture = try fixtureLoader.loadJSON(filename: "github_notifications.json")

        // Assert
        let unreadNotifications = githubData.notifications.filter { !$0.unread }
        XCTAssertFalse(unreadNotifications.isEmpty, "Should handle null/false boolean values")
    }

    func testFixtureLoaderCanLoadFromCustomDirectory() throws {
        // Arrange
        let customLoader = FixtureLoader(fixturesDirectory: "/tmp/custom_fixtures")

        // Assert
        XCTAssertNotNil(customLoader, "Should initialize with custom directory")
    }

    // MARK: - Error Case Tests

    func testLoadNonexistentFixtureThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadJSON(filename: "nonexistent.json") as SlackMessagesFixture,
            "Should throw error when fixture file doesn't exist"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoaderError,
                "Should throw FixtureLoaderError"
            )
        }
    }

    func testLoadInvalidJSONThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadJSON(filename: "invalid.json") as SlackMessagesFixture,
            "Should throw error when JSON is malformed"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoaderError,
                "Should throw FixtureLoaderError for invalid JSON"
            )
        }
    }

    func testLoadInvalidYAMLThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadYAML(filename: "invalid.yaml") as ConfigFixture,
            "Should throw error when YAML is malformed"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoaderError,
                "Should throw FixtureLoaderError for invalid YAML"
            )
        }
    }

    func testLoadJSONWithWrongTypeThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadJSON(filename: "slack_messages.json") as GmailMessagesFixture,
            "Should throw error when decoding to wrong type"
        ) { error in
            XCTAssertTrue(
                error is FixtureLoaderError || error is DecodingError,
                "Should throw decoding error"
            )
        }
    }

    func testLoadEmptyFixtureFileThrowsError() {
        // Act & Assert
        XCTAssertThrowsError(
            try fixtureLoader.loadJSON(filename: "empty.json") as SlackMessagesFixture,
            "Should throw error when fixture file is empty"
        )
    }

    // MARK: - Fixture Data Validation Tests

    func testSlackMessagesFixtureHasValidTimestamps() throws {
        // Act
        let slackData: SlackMessagesFixture = try fixtureLoader.loadJSON(filename: "slack_messages.json")

        // Assert
        for message in slackData.messages {
            XCTAssertGreaterThan(message.timestamp, 0, "Timestamp should be valid Unix timestamp")
        }
    }

    func testGmailMessagesFixtureHasValidEmailAddresses() throws {
        // Act
        let gmailData: GmailMessagesFixture = try fixtureLoader.loadJSON(filename: "gmail_messages.json")

        // Assert
        for message in gmailData.messages {
            XCTAssertTrue(message.from.contains("@"), "From address should be valid email")
        }
    }

    func testLinearIssuesFixtureHasValidStates() throws {
        // Act
        let linearData: LinearIssuesFixture = try fixtureLoader.loadJSON(filename: "linear_issues.json")

        // Assert
        let validStates = ["todo", "in_progress", "done", "canceled"]
        for issue in linearData.issues {
            XCTAssertTrue(
                validStates.contains(issue.state),
                "Issue state should be valid: \(issue.state)"
            )
        }
    }

    func testGitHubNotificationsFixtureHasValidReasons() throws {
        // Act
        let githubData: GitHubNotificationsFixture = try fixtureLoader.loadJSON(filename: "github_notifications.json")

        // Assert
        let validReasons = ["mention", "assign", "review_requested", "comment", "subscribed"]
        for notification in githubData.notifications {
            XCTAssertTrue(
                validReasons.contains(notification.reason),
                "Notification reason should be valid: \(notification.reason)"
            )
        }
    }

    func testCalendarEventsFixtureHasValidDateRanges() throws {
        // Act
        let calendarData: CalendarEventsFixture = try fixtureLoader.loadJSON(filename: "calendar_events.json")

        // Assert
        for event in calendarData.events {
            XCTAssertLessThanOrEqual(
                event.startTime,
                event.endTime,
                "Event start time should be before or equal to end time"
            )
        }
    }
}

// MARK: - Fixture Model Types (to be implemented)

struct SlackMessagesFixture: Codable {
    let messages: [SlackMessage]
}

struct SlackMessage: Codable {
    let id: String
    let text: String
    let user: String
    let timestamp: Double
    let channel: String
}

struct GmailMessagesFixture: Codable {
    let messages: [GmailMessage]
}

struct GmailMessage: Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timestamp: String
}

struct LinearIssuesFixture: Codable {
    let issues: [LinearIssue]
}

struct LinearIssue: Codable {
    let id: String
    let title: String
    let description: String
    let state: String
    let assignee: LinearUser?
    let labels: [String]
}

struct LinearUser: Codable {
    let id: String
    let name: String
    let email: String
}

struct GitHubNotificationsFixture: Codable {
    let notifications: [GitHubNotification]
}

struct GitHubNotification: Codable {
    let id: String
    let reason: String
    let unread: Bool
    let subject: GitHubSubject
    let repository: GitHubRepository
}

struct GitHubSubject: Codable {
    let title: String
    let type: String
    let url: String
}

struct GitHubRepository: Codable {
    let name: String
    let fullName: String
    let owner: String
}

struct CalendarEventsFixture: Codable {
    let events: [CalendarEvent]
}

struct CalendarEvent: Codable {
    let id: String
    let title: String
    let description: String?
    let startTime: String
    let endTime: String
    let location: String?
}

struct ConfigFixture: Codable {
    let plugins: [PluginConfig]
    let database: DatabaseConfig
    let refresh: RefreshConfig
}

struct PluginConfig: Codable {
    let name: String
    let enabled: Bool
    let config: [String: String]
}

struct DatabaseConfig: Codable {
    let path: String
}

struct RefreshConfig: Codable {
    let intervalMinutes: Int
}
