import Foundation

/// Mock HTTP client for testing
class MockHTTPClient: HTTPClient {
    private struct EndpointConfig {
        let response: String?
        let error: HTTPClientError?
        let requiredHeaders: [String: String]?
    }

    private var responses: [String: EndpointConfig] = [:]

    /// Register a successful response for a URL
    func registerResponse(for url: String, response: String, requiredHeaders: [String: String]? = nil) {
        responses[url] = EndpointConfig(
            response: response,
            error: nil,
            requiredHeaders: requiredHeaders
        )
    }

    /// Register an error for a URL
    func registerError(for url: String, error: HTTPClientError) {
        responses[url] = EndpointConfig(
            response: nil,
            error: error,
            requiredHeaders: nil
        )
    }

    func get(url: String, headers: [String: String]?) async throws -> String {
        try await executeRequest(url: url, headers: headers)
    }

    func post(url: String, body: String, headers: [String: String]?) async throws -> String {
        try await executeRequest(url: url, headers: headers)
    }

    func put(url: String, body: String, headers: [String: String]?) async throws -> String {
        try await executeRequest(url: url, headers: headers)
    }

    func delete(url: String, headers: [String: String]?) async throws -> String {
        try await executeRequest(url: url, headers: headers)
    }

    private func executeRequest(url: String, headers: [String: String]?) async throws -> String {
        // Validate URL format
        guard url.starts(with: "http://") || url.starts(with: "https://") else {
            throw HTTPClientError.invalidURL(url)
        }

        // Check if endpoint is registered
        guard let config = responses[url] else {
            throw HTTPClientError.endpointNotFound(url)
        }

        // Check if error should be thrown
        if let error = config.error {
            throw error
        }

        // Validate required headers
        if let requiredHeaders = config.requiredHeaders {
            let providedHeaders = headers ?? [:]
            for (key, value) in requiredHeaders {
                if providedHeaders[key] != value {
                    throw HTTPClientError.missingHeaders([key])
                }
            }
        }

        // Return response
        guard let response = config.response else {
            throw HTTPClientError.endpointNotFound(url)
        }

        return response
    }
}
