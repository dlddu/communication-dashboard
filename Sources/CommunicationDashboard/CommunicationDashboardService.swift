import Foundation
import GRDB

/// Service class for managing all communication plugins
class CommunicationDashboardService {
    private let database: DatabaseManager
    private let config: ConfigService
    private let httpClient: HTTPClient
    private let shellExecutor: ShellExecutor

    init(database: DatabaseManager, config: ConfigService, httpClient: HTTPClient, shellExecutor: ShellExecutor) {
        self.database = database
        self.config = config
        self.httpClient = httpClient
        self.shellExecutor = shellExecutor
    }

    /// Refresh data from all plugins
    func refreshAllPlugins() async throws {
        // Create plugin instances
        let slackPlugin = SlackPlugin(httpClient: httpClient)
        let gmailPlugin = GmailPlugin(httpClient: httpClient)
        let linearPlugin = LinearPlugin(httpClient: httpClient)
        let githubPlugin = GitHubPlugin(httpClient: httpClient)
        let calendarPlugin = CalendarPlugin(shellExecutor: shellExecutor)

        // Fetch data from all plugins
        async let slackMessages = try? await slackPlugin.fetchMessages()
        async let gmailMessages = try? await gmailPlugin.fetchMessages()
        async let linearIssues = try? await linearPlugin.fetchIssues()
        async let githubNotifications = try? await githubPlugin.fetchNotifications()
        async let calendarEvents = try? await calendarPlugin.fetchEvents()

        // Wait for all fetches to complete
        let results = await (slackMessages, gmailMessages, linearIssues, githubNotifications, calendarEvents)

        // Get database queue
        let dbQueue = try database.getDatabaseQueue()

        // Persist data to database
        try await dbQueue.write { db in
            // Insert Slack messages
            if let messages = results.0 {
                for message in messages {
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        arguments: [message.text, "slack:\(message.id)", Date(), Date()]
                    )
                }
            }

            // Insert Gmail messages
            if let messages = results.1 {
                for message in messages {
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        arguments: [message.subject, "gmail:\(message.id)", Date(), Date()]
                    )
                }
            }

            // Insert Linear issues
            if let issues = results.2 {
                for issue in issues {
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        arguments: [issue.title, "linear:\(issue.id)", Date(), Date()]
                    )
                }
            }

            // Insert GitHub notifications
            if let notifications = results.3 {
                for notification in notifications {
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        arguments: [notification.subject.title, "github:\(notification.id)", Date(), Date()]
                    )
                }
            }

            // Insert Calendar events
            if let events = results.4 {
                for event in events {
                    try db.execute(
                        sql: "INSERT OR REPLACE INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                        arguments: [event.title, "calendar:\(event.id)", Date(), Date()]
                    )
                }
            }
        }
    }
}

// Type alias for tests
typealias CommunicationDashboardApp = CommunicationDashboardService
