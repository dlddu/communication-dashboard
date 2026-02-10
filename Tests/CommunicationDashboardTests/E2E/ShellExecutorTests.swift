import XCTest
@testable import CommunicationDashboard

/// Tests for ShellExecutor protocol and MockShellExecutor implementation
/// These tests verify that shell commands can be mocked for E2E testing
final class ShellExecutorTests: XCTestCase {

    // MARK: - Happy Path Tests

    func testMockShellExecutorReturnsRegisteredOutput() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        let expectedOutput = "Calendar events loaded successfully"
        mockExecutor.registerOutput(
            for: "/usr/bin/python3 scripts/fetch_calendar.py",
            output: expectedOutput
        )

        // Act
        let output = try await mockExecutor.execute(command: "/usr/bin/python3 scripts/fetch_calendar.py")

        // Assert
        XCTAssertEqual(output, expectedOutput, "Should return registered output")
    }

    func testMockShellExecutorSupportsMultipleCommands() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(for: "ls -la", output: "total 0")
        mockExecutor.registerOutput(for: "pwd", output: "/tmp/test")

        // Act
        let lsOutput = try await mockExecutor.execute(command: "ls -la")
        let pwdOutput = try await mockExecutor.execute(command: "pwd")

        // Assert
        XCTAssertEqual(lsOutput, "total 0", "Should return ls output")
        XCTAssertEqual(pwdOutput, "/tmp/test", "Should return pwd output")
    }

    func testMockShellExecutorSupportsScriptWithArguments() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        let scriptOutput = """
        {
            "events": [
                {"title": "Meeting", "time": "2026-02-10T10:00:00Z"}
            ]
        }
        """
        mockExecutor.registerOutput(
            for: "python3 fetch_calendar.py --date 2026-02-10",
            output: scriptOutput
        )

        // Act
        let output = try await mockExecutor.execute(command: "python3 fetch_calendar.py --date 2026-02-10")

        // Assert
        XCTAssertTrue(output.contains("Meeting"), "Should return script output with arguments")
    }

    func testShellExecutorProtocolIsDefinedWithRequiredMethods() {
        // Assert - This test verifies protocol existence
        // The protocol should define:
        // - func execute(command: String) async throws -> String
        // - func execute(command: String, workingDirectory: String) async throws -> String

        // Note: This will fail until ShellExecutor protocol is defined
        let mockExecutor: ShellExecutor = MockShellExecutor()
        XCTAssertNotNil(mockExecutor, "ShellExecutor protocol should exist")
    }

    func testMockShellExecutorSupportsWorkingDirectory() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(
            for: "git status",
            output: "On branch main",
            workingDirectory: "/tmp/repo"
        )

        // Act
        let output = try await mockExecutor.execute(
            command: "git status",
            workingDirectory: "/tmp/repo"
        )

        // Assert
        XCTAssertEqual(output, "On branch main", "Should respect working directory")
    }

    // MARK: - Edge Case Tests

    func testMockShellExecutorHandlesEmptyOutput() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(for: "echo", output: "")

        // Act
        let output = try await mockExecutor.execute(command: "echo")

        // Assert
        XCTAssertEqual(output, "", "Should handle empty output")
    }

    func testMockShellExecutorHandlesMultilineOutput() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        let multilineOutput = """
        line 1
        line 2
        line 3
        """
        mockExecutor.registerOutput(for: "cat file.txt", output: multilineOutput)

        // Act
        let output = try await mockExecutor.execute(command: "cat file.txt")

        // Assert
        XCTAssertEqual(output, multilineOutput, "Should handle multiline output")
        XCTAssertEqual(output.components(separatedBy: "\n").count, 3, "Should preserve newlines")
    }

    func testMockShellExecutorCanBeReconfigured() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(for: "date", output: "2026-02-10")

        // Act - First call
        let firstOutput = try await mockExecutor.execute(command: "date")

        // Reconfigure
        mockExecutor.registerOutput(for: "date", output: "2026-02-11")
        let secondOutput = try await mockExecutor.execute(command: "date")

        // Assert
        XCTAssertEqual(firstOutput, "2026-02-10", "Should return first configured output")
        XCTAssertEqual(secondOutput, "2026-02-11", "Should return reconfigured output")
    }

    func testMockShellExecutorHandlesCommandsWithSpecialCharacters() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(
            for: "grep 'pattern' file.txt | awk '{print $1}'",
            output: "result"
        )

        // Act
        let output = try await mockExecutor.execute(command: "grep 'pattern' file.txt | awk '{print $1}'")

        // Assert
        XCTAssertEqual(output, "result", "Should handle commands with special characters")
    }

    func testMockShellExecutorTracksExecutionHistory() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(for: "cmd1", output: "out1")
        mockExecutor.registerOutput(for: "cmd2", output: "out2")

        // Act
        _ = try await mockExecutor.execute(command: "cmd1")
        _ = try await mockExecutor.execute(command: "cmd2")
        _ = try await mockExecutor.execute(command: "cmd1")

        // Assert
        let history = mockExecutor.getExecutionHistory()
        XCTAssertEqual(history.count, 3, "Should track all executions")
        XCTAssertEqual(history[0], "cmd1", "Should record commands in order")
        XCTAssertEqual(history[1], "cmd2", "Should record commands in order")
        XCTAssertEqual(history[2], "cmd1", "Should record duplicate commands")
    }

    // MARK: - Error Case Tests

    func testMockShellExecutorThrowsWhenCommandNotRegistered() async {
        // Arrange
        let mockExecutor = MockShellExecutor()

        // Act & Assert
        do {
            _ = try await mockExecutor.execute(command: "unregistered_command")
            XCTFail("Should throw error for unregistered command")
        } catch {
            XCTAssertTrue(
                error is ShellExecutorError,
                "Should throw ShellExecutorError when command not found"
            )
        }
    }

    func testMockShellExecutorCanSimulateCommandFailure() async {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerError(
            for: "failing_command",
            error: ShellExecutorError.commandFailed(exitCode: 1, stderr: "Permission denied")
        )

        // Act & Assert
        do {
            _ = try await mockExecutor.execute(command: "failing_command")
            XCTFail("Should throw command failure error")
        } catch let error as ShellExecutorError {
            if case .commandFailed(let exitCode, let stderr) = error {
                XCTAssertEqual(exitCode, 1, "Should return exit code 1")
                XCTAssertEqual(stderr, "Permission denied", "Should return stderr message")
            } else {
                XCTFail("Wrong error type thrown")
            }
        }
    }

    func testMockShellExecutorCanSimulateTimeout() async {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerError(
            for: "long_running_command",
            error: ShellExecutorError.timeout(seconds: 30)
        )

        // Act & Assert
        do {
            _ = try await mockExecutor.execute(command: "long_running_command")
            XCTFail("Should throw timeout error")
        } catch let error as ShellExecutorError {
            if case .timeout(let seconds) = error {
                XCTAssertEqual(seconds, 30, "Should report timeout duration")
            } else {
                XCTFail("Wrong error type thrown")
            }
        }
    }

    func testMockShellExecutorThrowsWhenWorkingDirectoryMismatch() async {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(
            for: "ls",
            output: "file1.txt",
            workingDirectory: "/tmp/dir1"
        )

        // Act & Assert
        do {
            _ = try await mockExecutor.execute(command: "ls", workingDirectory: "/tmp/dir2")
            XCTFail("Should throw error when working directory doesn't match")
        } catch {
            XCTAssertTrue(
                error is ShellExecutorError,
                "Should throw ShellExecutorError for directory mismatch"
            )
        }
    }

    func testMockShellExecutorSupportsEnvironmentVariables() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerOutput(
            for: "env",
            output: "PATH=/usr/bin\nHOME=/Users/test",
            environment: ["PATH": "/usr/bin", "HOME": "/Users/test"]
        )

        // Act
        let output = try await mockExecutor.execute(
            command: "env",
            environment: ["PATH": "/usr/bin", "HOME": "/Users/test"]
        )

        // Assert
        XCTAssertTrue(output.contains("PATH=/usr/bin"), "Should handle environment variables")
    }

    func testMockShellExecutorCanSimulateInteractiveCommand() async throws {
        // Arrange
        let mockExecutor = MockShellExecutor()
        mockExecutor.registerInteractiveOutput(
            for: "python3 interactive_script.py",
            interactions: [
                .prompt("Enter name:"),
                .input("John"),
                .prompt("Enter age:"),
                .input("30"),
                .output("User: John, Age: 30")
            ]
        )

        // Act
        let output = try await mockExecutor.executeInteractive(
            command: "python3 interactive_script.py",
            inputs: ["John", "30"]
        )

        // Assert
        XCTAssertTrue(output.contains("User: John, Age: 30"), "Should handle interactive commands")
    }
}
