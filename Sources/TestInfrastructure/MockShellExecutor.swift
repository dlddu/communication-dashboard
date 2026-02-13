import Foundation

/// Mock implementation of ShellExecutorProtocol for testing
public class MockShellExecutor: ShellExecutorProtocol {
    public enum ExecutorError: Error {
        case commandNotRegistered(String)
        case invalidTimeout
    }

    public enum FixtureError: Error {
        case fixtureNotFound(String)
    }

    private struct CommandRegistration {
        let output: String
        let exitCode: Int32
        let error: String?
        let delay: TimeInterval
    }

    private struct CommandExecution {
        let command: String
        let timestamp: Date
    }

    private var registeredCommands: [String: CommandRegistration] = [:]
    private var registeredPatterns: [(pattern: String, registration: CommandRegistration)] = []
    private var executionHistory: [String: [CommandExecution]] = [:]
    private var environmentVariables: [String: String] = [:]
    private var workingDirectory: String = FileManager.default.currentDirectoryPath

    private let fixtureLoader = FixtureLoader()

    public init() {}

    // MARK: - Command Registration

    /// Register a command with expected output
    public func registerCommand(
        command: String,
        output: String,
        exitCode: Int32,
        error: String? = nil,
        delay: TimeInterval = 0
    ) {
        registeredCommands[command] = CommandRegistration(
            output: output,
            exitCode: exitCode,
            error: error,
            delay: delay
        )
    }

    /// Register a command pattern (regex) with expected output
    public func registerCommandPattern(
        pattern: String,
        output: String,
        exitCode: Int32,
        error: String? = nil,
        delay: TimeInterval = 0
    ) {
        let registration = CommandRegistration(
            output: output,
            exitCode: exitCode,
            error: error,
            delay: delay
        )
        registeredPatterns.append((pattern: pattern, registration: registration))
    }

    /// Register a command with fixture file
    public func registerCommandWithFixture(
        command: String,
        fixturePath: String,
        exitCode: Int32,
        error: String? = nil
    ) throws {
        do {
            let output = try fixtureLoader.loadFixtureAsString(path: fixturePath)
            registerCommand(command: command, output: output, exitCode: exitCode, error: error)
        } catch {
            throw FixtureError.fixtureNotFound("Failed to load fixture: \(fixturePath)")
        }
    }

    // MARK: - ShellExecutorProtocol

    public func execute(_ command: String) throws -> ShellExecutionResult {
        return try execute(command, timeout: 0)
    }

    public func execute(_ command: String, timeout: TimeInterval) throws -> ShellExecutionResult {
        // Validate timeout
        if timeout < 0 {
            throw ExecutorError.invalidTimeout
        }

        // Record execution
        let execution = CommandExecution(command: command, timestamp: Date())
        executionHistory[command, default: []].append(execution)

        // Find matching registration
        let registration: CommandRegistration

        if let exact = registeredCommands[command] {
            registration = exact
        } else if let pattern = findMatchingPattern(for: command) {
            registration = pattern
        } else {
            throw ExecutorError.commandNotRegistered("Command not registered: \(command)")
        }

        // Simulate delay
        if registration.delay > 0 {
            Thread.sleep(forTimeInterval: registration.delay)
        }

        return ShellExecutionResult(
            output: registration.output,
            exitCode: registration.exitCode,
            error: registration.error
        )
    }

    // MARK: - Execution Tracking

    /// Get execution count for a command
    public func executionCount(for command: String) -> Int {
        return executionHistory[command]?.count ?? 0
    }

    /// Get all executions for a command
    public func capturedExecutions(for command: String) -> [CommandExecution] {
        return executionHistory[command] ?? []
    }

    // MARK: - Environment Variables

    /// Set environment variable
    public func setEnvironmentVariable(_ key: String, value: String) {
        environmentVariables[key] = value
    }

    /// Get environment variable
    public func getEnvironmentVariable(_ key: String) -> String? {
        return environmentVariables[key]
    }

    // MARK: - Working Directory

    /// Set working directory
    public func setWorkingDirectory(_ path: String) {
        workingDirectory = path
    }

    /// Get working directory
    public func getWorkingDirectory() -> String {
        return workingDirectory
    }

    // MARK: - Reset

    /// Reset all registrations and history
    public func reset() {
        registeredCommands.removeAll()
        registeredPatterns.removeAll()
        executionHistory.removeAll()
        environmentVariables.removeAll()
        workingDirectory = FileManager.default.currentDirectoryPath
    }

    // MARK: - Private Helpers

    private func findMatchingPattern(for command: String) -> CommandRegistration? {
        for (pattern, registration) in registeredPatterns {
            if command.range(of: pattern, options: .regularExpression) != nil {
                return registration
            }
        }
        return nil
    }
}
