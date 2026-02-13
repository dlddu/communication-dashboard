import Foundation

/// Common error types for test infrastructure
public enum TestInfrastructureError: Error {
    case serverError(String)
    case fixtureError(String)
    case executorError(String)
    case parseError(String)
    case encodingError(String)
    case invalidPath(String)
}
