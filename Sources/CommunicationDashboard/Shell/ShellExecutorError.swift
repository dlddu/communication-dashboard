import Foundation

/// Errors that can occur during shell command execution
enum ShellExecutorError: Error, LocalizedError {
    case commandNotFound(String)
    case commandFailed(exitCode: Int, stderr: String)
    case timeout(seconds: Int)
    case workingDirectoryMismatch(expected: String, actual: String)
    case environmentMismatch

    var errorDescription: String? {
        switch self {
        case .commandNotFound(let command):
            return "Command not found: \(command)"
        case .commandFailed(let exitCode, let stderr):
            return "Command failed with exit code \(exitCode): \(stderr)"
        case .timeout(let seconds):
            return "Command timed out after \(seconds) seconds"
        case .workingDirectoryMismatch(let expected, let actual):
            return "Working directory mismatch: expected \(expected), got \(actual)"
        case .environmentMismatch:
            return "Environment variables mismatch"
        }
    }
}
