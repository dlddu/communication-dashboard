import Foundation

/// HTTP client protocol for making network requests
protocol HTTPClient {
    func get(url: String, headers: [String: String]?) async throws -> String
    func post(url: String, body: String, headers: [String: String]?) async throws -> String
    func put(url: String, body: String, headers: [String: String]?) async throws -> String
    func delete(url: String, headers: [String: String]?) async throws -> String
}

// Extension to make headers optional
extension HTTPClient {
    func get(url: String) async throws -> String {
        try await get(url: url, headers: nil)
    }

    func post(url: String, body: String) async throws -> String {
        try await post(url: url, body: body, headers: nil)
    }

    func put(url: String, body: String) async throws -> String {
        try await put(url: url, body: body, headers: nil)
    }

    func delete(url: String) async throws -> String {
        try await delete(url: url, headers: nil)
    }
}
