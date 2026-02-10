import Foundation

/// Errors that can occur when loading fixtures
enum FixtureLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case fileReadError(String)
    case decodingError(String, Error)
    case emptyFile(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Fixture file not found: \(filename)"
        case .fileReadError(let filename):
            return "Failed to read fixture file: \(filename)"
        case .decodingError(let filename, let error):
            return "Failed to decode fixture file \(filename): \(error.localizedDescription)"
        case .emptyFile(let filename):
            return "Fixture file is empty: \(filename)"
        }
    }
}
