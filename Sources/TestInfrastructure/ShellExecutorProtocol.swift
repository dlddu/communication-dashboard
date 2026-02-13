import Foundation

/// Result of shell command execution
public struct ShellExecutionResult {
    public let output: String
    public let exitCode: Int32
    public let error: String?

    public init(output: String, exitCode: Int32, error: String? = nil) {
        self.output = output
        self.exitCode = exitCode
        self.error = error
    }
}

/// Protocol for shell command execution
public protocol ShellExecutorProtocol {
    /// Execute a shell command
    func execute(_ command: String) throws -> ShellExecutionResult

    /// Execute a shell command with timeout
    func execute(_ command: String, timeout: TimeInterval) throws -> ShellExecutionResult
}
