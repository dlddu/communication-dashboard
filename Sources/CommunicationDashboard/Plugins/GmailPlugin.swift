import Foundation

/// Gmail message structure
struct GmailMessage: Codable {
    let id: String
    let from: String
    let subject: String
    let snippet: String
    let timestamp: String
}

/// Plugin for fetching Gmail messages
class GmailPlugin {
    private let httpClient: HTTPClient
    private let apiURL = "https://www.googleapis.com/gmail/v1/messages"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchMessages() async throws -> [GmailMessage] {
        let response = try await httpClient.get(url: apiURL)
        let data = response.data(using: .utf8)!

        struct Response: Codable {
            let messages: [GmailMessage]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.messages
    }
}
