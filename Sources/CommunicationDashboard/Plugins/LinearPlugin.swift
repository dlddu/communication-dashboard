import Foundation

/// Linear issue structure
struct LinearIssue: Codable {
    let id: String
    let title: String
    let description: String
    let state: String
    let assignee: LinearUser?
    let labels: [String]
}

/// Linear user structure
struct LinearUser: Codable {
    let id: String
    let name: String
    let email: String
}

/// Plugin for fetching Linear issues
class LinearPlugin {
    private let httpClient: HTTPClient
    private let apiURL = "https://api.linear.app/graphql"

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchIssues() async throws -> [LinearIssue] {
        let response = try await httpClient.post(url: apiURL, body: "{\"query\": \"...\"}")
        let data = response.data(using: .utf8)!

        struct Response: Codable {
            let issues: [LinearIssue]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.issues
    }
}
