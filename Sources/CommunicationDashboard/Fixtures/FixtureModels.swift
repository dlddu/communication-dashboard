import Foundation

// MARK: - Slack Fixtures

public struct SlackMessagesFixture: Codable {
    public let messages: [SlackMessageFixture]

    public init(messages: [SlackMessageFixture]) {
        self.messages = messages
    }
}

public struct SlackMessageFixture: Codable {
    public let id: String
    public let text: String
    public let user: String
    public let timestamp: Double
    public let channel: String

    public init(id: String, text: String, user: String, timestamp: Double, channel: String) {
        self.id = id
        self.text = text
        self.user = user
        self.timestamp = timestamp
        self.channel = channel
    }
}

// MARK: - Gmail Fixtures

public struct GmailMessagesFixture: Codable {
    public let messages: [GmailMessageFixture]

    public init(messages: [GmailMessageFixture]) {
        self.messages = messages
    }
}

public struct GmailMessageFixture: Codable {
    public let id: String
    public let from: String
    public let subject: String
    public let snippet: String
    public let timestamp: String

    public init(id: String, from: String, subject: String, snippet: String, timestamp: String) {
        self.id = id
        self.from = from
        self.subject = subject
        self.snippet = snippet
        self.timestamp = timestamp
    }
}

// MARK: - Linear Fixtures

public struct LinearIssuesFixture: Codable {
    public let issues: [LinearIssueFixture]

    public init(issues: [LinearIssueFixture]) {
        self.issues = issues
    }
}

public struct LinearIssueFixture: Codable {
    public let id: String
    public let title: String
    public let description: String
    public let state: String
    public let assignee: LinearUserFixture?
    public let labels: [String]

    public init(id: String, title: String, description: String, state: String, assignee: LinearUserFixture?, labels: [String]) {
        self.id = id
        self.title = title
        self.description = description
        self.state = state
        self.assignee = assignee
        self.labels = labels
    }
}

public struct LinearUserFixture: Codable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

// MARK: - GitHub Fixtures

public struct GitHubNotificationsFixture: Codable {
    public let notifications: [GitHubNotificationFixture]

    public init(notifications: [GitHubNotificationFixture]) {
        self.notifications = notifications
    }
}

public struct GitHubNotificationFixture: Codable {
    public let id: String
    public let reason: String
    public let unread: Bool
    public let subject: GitHubSubjectFixture
    public let repository: GitHubRepositoryFixture

    public init(id: String, reason: String, unread: Bool, subject: GitHubSubjectFixture, repository: GitHubRepositoryFixture) {
        self.id = id
        self.reason = reason
        self.unread = unread
        self.subject = subject
        self.repository = repository
    }
}

public struct GitHubSubjectFixture: Codable {
    public let title: String
    public let type: String
    public let url: String

    public init(title: String, type: String, url: String) {
        self.title = title
        self.type = type
        self.url = url
    }
}

public struct GitHubRepositoryFixture: Codable {
    public let name: String
    public let fullName: String
    public let owner: String

    public init(name: String, fullName: String, owner: String) {
        self.name = name
        self.fullName = fullName
        self.owner = owner
    }
}

// MARK: - Calendar Fixtures

public struct CalendarEventsFixture: Codable {
    public let events: [CalendarEventFixture]

    public init(events: [CalendarEventFixture]) {
        self.events = events
    }
}

public struct CalendarEventFixture: Codable {
    public let id: String
    public let title: String
    public let description: String?
    public let startTime: String
    public let endTime: String
    public let location: String?

    public init(id: String, title: String, description: String?, startTime: String, endTime: String, location: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
    }
}

// MARK: - Config Fixtures

public struct ConfigFixture: Codable {
    public let plugins: [PluginConfig]
    public let database: DatabaseConfig
    public let refresh: RefreshConfig

    public init(plugins: [PluginConfig], database: DatabaseConfig, refresh: RefreshConfig) {
        self.plugins = plugins
        self.database = database
        self.refresh = refresh
    }
}

public struct PluginConfig: Codable {
    public let name: String
    public let enabled: Bool
    public let config: [String: String]

    public init(name: String, enabled: Bool, config: [String: String]) {
        self.name = name
        self.enabled = enabled
        self.config = config
    }
}

public struct DatabaseConfig: Codable {
    public let path: String

    public init(path: String) {
        self.path = path
    }
}

public struct RefreshConfig: Codable {
    public let intervalMinutes: Int

    public init(intervalMinutes: Int) {
        self.intervalMinutes = intervalMinutes
    }
}
