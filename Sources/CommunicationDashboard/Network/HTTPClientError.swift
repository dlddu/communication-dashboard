import Foundation

/// Errors that can occur during HTTP operations
enum HTTPClientError: Error, LocalizedError {
    case networkError(String)
    case invalidURL(String)
    case timeout(seconds: Int)
    case httpError(statusCode: Int, message: String)
    case endpointNotFound(String)
    case missingHeaders([String])

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .timeout(let seconds):
            return "Request timed out after \(seconds) seconds"
        case .httpError(let statusCode, let message):
            return "HTTP error \(statusCode): \(message)"
        case .endpointNotFound(let url):
            return "Endpoint not found: \(url)"
        case .missingHeaders(let headers):
            return "Missing required headers: \(headers.joined(separator: ", "))"
        }
    }
}
