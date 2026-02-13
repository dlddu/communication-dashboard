import XCTest
import Foundation
@testable import TestInfrastructure

final class MockShellExecutorTests: XCTestCase {
    var mockExecutor: MockShellExecutor!

    override func setUp() {
        super.setUp()
        // Use #file to locate test fixtures relative to the test file
        let testFileURL = URL(fileURLWithPath: #file)
        let fixturesDirectory = testFileURL
            .deletingLastPathComponent()  // Tests/TestInfrastructureTests/
            .deletingLastPathComponent()  // Tests/
            .appendingPathComponent("Fixtures")
        mockExecutor = MockShellExecutor(fixturesDirectory: fixturesDirectory)
    }

    override func tearDown() {
        mockExecutor = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testExecuteCommandReturnsRegisteredOutput() throws {
        // Arrange
        let command = "echo 'Hello, World!'"
        let expectedOutput = "Hello, World!\n"

        mockExecutor.registerCommand(
            command: command,
            output: expectedOutput,
            exitCode: 0
        )

        // Act
        let result = try mockExecutor.execute(command)

        // Assert
        XCTAssertEqual(result.output, expectedOutput, "Should return registered output")
        XCTAssertEqual(result.exitCode, 0, "Should return success exit code")
        XCTAssertNil(result.error, "Should not have error")
    }

    func testExecuteCommandWithErrorOutput() throws {
        // Arrange
        let command = "invalid_command"
        let errorOutput = "command not found: invalid_command"

        mockExecutor.registerCommand(
            command: command,
            output: "",
            exitCode: 127,
            error: errorOutput
        )

        // Act
        let result = try mockExecutor.execute(command)

        // Assert
        XCTAssertEqual(result.exitCode, 127, "Should return error exit code")
        XCTAssertEqual(result.error, errorOutput, "Should return error message")
    }

    func testRegisterCommandWithFixturePath() throws {
        // Arrange
        let command = "cat config.yaml"

        try mockExecutor.registerCommandWithFixture(
            command: command,
            fixturePath: "Shell/cat_config_output.txt",
            exitCode: 0
        )

        // Act
        let result = try mockExecutor.execute(command)

        // Assert
        XCTAssertFalse(result.output.isEmpty, "Should load output from fixture file")
        XCTAssertEqual(result.exitCode, 0, "Should return success exit code")
    }

    func testExecuteMultipleCommands() throws {
        // Arrange
        mockExecutor.registerCommand(command: "pwd", output: "/home/user\n", exitCode: 0)
        mockExecutor.registerCommand(command: "whoami", output: "testuser\n", exitCode: 0)

        // Act
        let result1 = try mockExecutor.execute("pwd")
        let result2 = try mockExecutor.execute("whoami")

        // Assert
        XCTAssertEqual(result1.output, "/home/user\n")
        XCTAssertEqual(result2.output, "testuser\n")
    }

    func testCommandExecutionTracking() throws {
        // Arrange
        mockExecutor.registerCommand(command: "git status", output: "clean", exitCode: 0)

        // Act
        _ = try mockExecutor.execute("git status")
        _ = try mockExecutor.execute("git status")

        // Assert
        let count = mockExecutor.executionCount(for: "git status")
        XCTAssertEqual(count, 2, "Should track command execution count")
    }

    func testCaptureCommandArguments() throws {
        // Arrange
        mockExecutor.registerCommand(
            command: "git commit -m 'test message'",
            output: "committed",
            exitCode: 0
        )

        // Act
        _ = try mockExecutor.execute("git commit -m 'test message'")

        // Assert
        let executions = mockExecutor.capturedExecutions(for: "git commit -m 'test message'")
        XCTAssertEqual(executions.count, 1, "Should capture command execution")
        XCTAssertEqual(executions.first?.command, "git commit -m 'test message'")
    }

    func testRegisterCommandPattern() throws {
        // Arrange
        mockExecutor.registerCommandPattern(
            pattern: "git commit -m .*",
            output: "committed",
            exitCode: 0
        )

        // Act
        let result1 = try mockExecutor.execute("git commit -m 'message 1'")
        let result2 = try mockExecutor.execute("git commit -m 'message 2'")

        // Assert
        XCTAssertEqual(result1.output, "committed", "Should match pattern for first command")
        XCTAssertEqual(result2.output, "committed", "Should match pattern for second command")
    }

    func testEnvironmentVariables() throws {
        // Arrange
        let command = "echo $HOME"
        mockExecutor.setEnvironmentVariable("HOME", value: "/home/testuser")
        mockExecutor.registerCommand(command: command, output: "/home/testuser\n", exitCode: 0)

        // Act
        let result = try mockExecutor.execute(command)

        // Assert
        XCTAssertEqual(result.output, "/home/testuser\n")
        XCTAssertEqual(mockExecutor.getEnvironmentVariable("HOME"), "/home/testuser")
    }

    func testWorkingDirectory() throws {
        // Arrange
        mockExecutor.setWorkingDirectory("/tmp/test")

        // Act
        let workingDir = mockExecutor.getWorkingDirectory()

        // Assert
        XCTAssertEqual(workingDir, "/tmp/test", "Should set working directory")
    }

    // MARK: - Edge Case Tests

    func testExecuteSameCommandMultipleTimes() throws {
        // Arrange
        mockExecutor.registerCommand(command: "date", output: "2026-02-13\n", exitCode: 0)

        // Act
        let result1 = try mockExecutor.execute("date")
        let result2 = try mockExecutor.execute("date")
        let result3 = try mockExecutor.execute("date")

        // Assert
        XCTAssertEqual(result1.output, result2.output)
        XCTAssertEqual(result2.output, result3.output)

        let count = mockExecutor.executionCount(for: "date")
        XCTAssertEqual(count, 3, "Should track multiple executions")
    }

    func testResetClearsAllRegistrations() throws {
        // Arrange
        mockExecutor.registerCommand(command: "test1", output: "output1", exitCode: 0)
        mockExecutor.registerCommand(command: "test2", output: "output2", exitCode: 0)

        // Act
        mockExecutor.reset()

        // Assert
        XCTAssertThrowsError(
            try mockExecutor.execute("test1"),
            "Should throw after reset"
        )
        XCTAssertEqual(mockExecutor.executionCount(for: "test1"), 0, "Execution count should be reset")
    }

    func testCommandWithTimeout() throws {
        // Arrange
        mockExecutor.registerCommand(
            command: "sleep 10",
            output: "",
            exitCode: 124,
            delay: 0.1
        )

        // Act
        let result = try mockExecutor.execute("sleep 10", timeout: 0.2)

        // Assert
        XCTAssertEqual(result.exitCode, 124, "Should return timeout exit code")
    }

    func testEmptyCommandOutput() throws {
        // Arrange
        mockExecutor.registerCommand(command: "true", output: "", exitCode: 0)

        // Act
        let result = try mockExecutor.execute("true")

        // Assert
        XCTAssertTrue(result.output.isEmpty, "Output should be empty")
        XCTAssertEqual(result.exitCode, 0, "Should succeed")
    }

    func testCommandWithMultilineOutput() throws {
        // Arrange
        let multilineOutput = """
        line 1
        line 2
        line 3
        """

        mockExecutor.registerCommand(
            command: "cat file.txt",
            output: multilineOutput,
            exitCode: 0
        )

        // Act
        let result = try mockExecutor.execute("cat file.txt")

        // Assert
        XCTAssertEqual(result.output, multilineOutput, "Should preserve multiline output")
    }

    // MARK: - Error Case Tests

    func testExecuteUnregisteredCommandThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try mockExecutor.execute("unregistered_command"),
            "Should throw error for unregistered command"
        ) { error in
            XCTAssertTrue(
                error is MockShellExecutor.ExecutorError,
                "Should throw ExecutorError"
            )
        }
    }

    func testRegisterCommandWithInvalidFixtureThrows() {
        // Act & Assert
        XCTAssertThrowsError(
            try mockExecutor.registerCommandWithFixture(
                command: "test",
                fixturePath: "nonexistent.txt",
                exitCode: 0
            ),
            "Should throw error when fixture file doesn't exist"
        ) { error in
            XCTAssertTrue(
                error is MockShellExecutor.FixtureError,
                "Should throw FixtureError"
            )
        }
    }

    func testExecuteWithNegativeTimeoutThrows() throws {
        // Arrange
        mockExecutor.registerCommand(command: "test", output: "", exitCode: 0)

        // Act & Assert
        XCTAssertThrowsError(
            try mockExecutor.execute("test", timeout: -1.0),
            "Should throw error for negative timeout"
        ) { error in
            XCTAssertTrue(
                error is MockShellExecutor.ExecutorError,
                "Should throw ExecutorError"
            )
        }
    }

    func testCommandFailureWithNonZeroExitCode() throws {
        // Arrange
        mockExecutor.registerCommand(
            command: "false",
            output: "",
            exitCode: 1
        )

        // Act
        let result = try mockExecutor.execute("false")

        // Assert
        XCTAssertEqual(result.exitCode, 1, "Should return failure exit code")
    }

    // MARK: - Integration Tests with Protocol

    func testConformsToShellExecutorProtocol() {
        // Assert
        XCTAssertTrue(
            mockExecutor is ShellExecutorProtocol,
            "MockShellExecutor should conform to ShellExecutorProtocol"
        )
    }

    func testRealExecutorCanBeSwappedWithMock() throws {
        // Arrange
        func executeWithShellExecutor(_ executor: ShellExecutorProtocol, command: String) throws -> String {
            let result = try executor.execute(command)
            return result.output
        }

        mockExecutor.registerCommand(command: "test", output: "mocked output", exitCode: 0)

        // Act
        let output = try executeWithShellExecutor(mockExecutor, command: "test")

        // Assert
        XCTAssertEqual(output, "mocked output", "Should work with protocol abstraction")
    }
}
