import Foundation

/// Protocol for executing shell commands
protocol ShellExecutor {
    func execute(command: String, workingDirectory: String?, environment: [String: String]?) async throws -> String
    func executeInteractive(command: String, inputs: [String], workingDirectory: String?, environment: [String: String]?) async throws -> String
}

// Extensions to make parameters optional
extension ShellExecutor {
    func execute(command: String) async throws -> String {
        try await execute(command: command, workingDirectory: nil, environment: nil)
    }

    func execute(command: String, workingDirectory: String) async throws -> String {
        try await execute(command: command, workingDirectory: workingDirectory, environment: nil)
    }

    func execute(command: String, environment: [String: String]) async throws -> String {
        try await execute(command: command, workingDirectory: nil, environment: environment)
    }

    func executeInteractive(command: String, inputs: [String]) async throws -> String {
        try await executeInteractive(command: command, inputs: inputs, workingDirectory: nil, environment: nil)
    }
}
