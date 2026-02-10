import Foundation

/// Slack message structure
struct SlackMessage: Codable {
    let id: String
    let text: String
    let user: String
    let timestamp: Double
    let channel: String
}

/// Plugin for fetching Slack messages
class SlackPlugin {
    private let httpClient: HTTPClient
    private let apiURL = "https://slack.com/api/conversations.history"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchMessages() async throws -> [SlackMessage] {
        let response = try await httpClient.get(url: apiURL)
        let data = response.data(using: .utf8)!

        struct Response: Codable {
            let messages: [SlackMessage]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.messages
    }
}
