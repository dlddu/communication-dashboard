import Foundation

/// Mock shell executor for testing
class MockShellExecutor: ShellExecutor {
    private struct CommandConfig {
        let output: String?
        let error: ShellExecutorError?
        let workingDirectory: String?
        let environment: [String: String]?
        let interactions: [Interaction]?
    }

    enum Interaction {
        case prompt(String)
        case input(String)
        case output(String)
    }

    private var commands: [String: CommandConfig] = [:]
    private var executionHistory: [String] = []

    /// Register output for a command
    func registerOutput(for command: String, output: String, workingDirectory: String? = nil, environment: [String: String]? = nil) {
        commands[command] = CommandConfig(
            output: output,
            error: nil,
            workingDirectory: workingDirectory,
            environment: environment,
            interactions: nil
        )
    }

    /// Register error for a command
    func registerError(for command: String, error: ShellExecutorError) {
        commands[command] = CommandConfig(
            output: nil,
            error: error,
            workingDirectory: nil,
            environment: nil,
            interactions: nil
        )
    }

    /// Register interactive command with interactions
    func registerInteractiveOutput(for command: String, interactions: [Interaction]) {
        commands[command] = CommandConfig(
            output: nil,
            error: nil,
            workingDirectory: nil,
            environment: nil,
            interactions: interactions
        )
    }

    /// Get execution history
    func getExecutionHistory() -> [String] {
        return executionHistory
    }

    func execute(command: String, workingDirectory: String?, environment: [String: String]?) async throws -> String {
        executionHistory.append(command)

        // Check if command is registered
        guard let config = commands[command] else {
            throw ShellExecutorError.commandNotFound(command)
        }

        // Check if error should be thrown
        if let error = config.error {
            throw error
        }

        // Validate working directory if specified
        if let expectedDir = config.workingDirectory {
            if let actualDir = workingDirectory {
                if expectedDir != actualDir {
                    throw ShellExecutorError.workingDirectoryMismatch(expected: expectedDir, actual: actualDir)
                }
            } else {
                throw ShellExecutorError.commandNotFound(command)
            }
        }

        // Validate environment if specified
        if let expectedEnv = config.environment {
            if let actualEnv = environment {
                if expectedEnv != actualEnv {
                    throw ShellExecutorError.environmentMismatch
                }
            } else {
                throw ShellExecutorError.commandNotFound(command)
            }
        }

        // Return output
        guard let output = config.output else {
            throw ShellExecutorError.commandNotFound(command)
        }

        return output
    }

    func executeInteractive(command: String, inputs: [String], workingDirectory: String?, environment: [String: String]?) async throws -> String {
        executionHistory.append(command)

        // Check if command is registered
        guard let config = commands[command], let interactions = config.interactions else {
            throw ShellExecutorError.commandNotFound(command)
        }

        // Extract output from interactions
        var output = ""
        for interaction in interactions {
            if case .output(let text) = interaction {
                output = text
            }
        }

        return output
    }
}
