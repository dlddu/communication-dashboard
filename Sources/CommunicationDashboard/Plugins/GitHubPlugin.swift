import Foundation

/// GitHub notification structure
struct GitHubNotification: Codable {
    let id: String
    let reason: String
    let unread: Bool
    let subject: GitHubSubject
    let repository: GitHubRepository
}

/// GitHub subject structure
struct GitHubSubject: Codable {
    let title: String
    let type: String
    let url: String
}

/// GitHub repository structure
struct GitHubRepository: Codable {
    let name: String
    let fullName: String
    let owner: String
}

/// Plugin for fetching GitHub notifications
class GitHubPlugin {
    private let httpClient: HTTPClient
    private let apiURL = "https://api.github.com/notifications"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchNotifications() async throws -> [GitHubNotification] {
        let response = try await httpClient.get(url: apiURL)
        let data = response.data(using: .utf8)!

        struct Response: Codable {
            let notifications: [GitHubNotification]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.notifications
    }
}
