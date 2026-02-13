import XCTest
import Foundation
@testable import TestInfrastructure
@testable import CommunicationDashboard

/// Integration tests that validate all E2E infrastructure components work together
final class E2EInfrastructureIntegrationTests: XCTestCase {
    var mockServer: MockHTTPServer!
    var mockShell: MockShellExecutor!
    var fixtureLoader: FixtureLoader!
    var databaseManager: DatabaseManager!

    override func setUp() {
        super.setUp()
        mockServer = MockHTTPServer()
        mockShell = MockShellExecutor()
        fixtureLoader = FixtureLoader()
        databaseManager = DatabaseManager(inMemory: true)
    }

    override func tearDown() {
        mockServer.stop()
        mockServer = nil
        mockShell = nil
        fixtureLoader = nil
        databaseManager = nil
        super.tearDown()
    }

    // MARK: - Integration: Fixture Loader + Mock HTTP Server

    func testLoadFixtureAndRegisterWithMockServer() throws {
        // Arrange
        try mockServer.start()
        let fixtureData = try fixtureLoader.loadFixture(path: "HTTP/plugin_response.json")

        // Act
        mockServer.register(
            endpoint: "/api/plugin",
            method: "GET",
            statusCode: 200,
            responseData: fixtureData,
            headers: ["Content-Type": "application/json"]
        )

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/plugin")!
        let expectation = expectation(description: "HTTP request")

        URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String {
                XCTAssertEqual(status, "success", "Should return fixture data from HTTP server")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    func testRegisterFixtureDirectlyInMockServer() throws {
        // Arrange
        try mockServer.start()

        // Act
        try mockServer.registerFixture(
            endpoint: "/api/config",
            method: "GET",
            fixturePath: "HTTP/plugin_response.json"
        )

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/config")!
        let expectation = expectation(description: "Fixture HTTP request")

        URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(data)

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertNotNil(json["status"], "Should load and serve fixture")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Integration: Fixture Loader + Mock Shell Executor

    func testLoadFixtureAndRegisterWithMockShell() throws {
        // Arrange
        let fixtureContent = try fixtureLoader.loadFixtureAsString(path: "Shell/cat_config_output.txt")

        // Act
        mockShell.registerCommand(
            command: "cat ~/.commdash/config.yaml",
            output: fixtureContent,
            exitCode: 0
        )

        // Assert
        let result = try mockShell.execute("cat ~/.commdash/config.yaml")
        XCTAssertEqual(result.output, fixtureContent, "Should return fixture content from shell command")
        XCTAssertEqual(result.exitCode, 0)
    }

    func testRegisterFixtureDirectlyInMockShell() throws {
        // Act
        try mockShell.registerCommandWithFixture(
            command: "cat config.yaml",
            fixturePath: "Shell/cat_config_output.txt",
            exitCode: 0
        )

        // Assert
        let result = try mockShell.execute("cat config.yaml")
        XCTAssertFalse(result.output.isEmpty, "Should load and return fixture from shell mock")
    }

    // MARK: - Integration: All Components Together

    func testCompleteE2EScenarioWithAllComponents() throws {
        // Arrange - Setup all infrastructure components
        try mockServer.start()
        try databaseManager.initialize()

        // Setup HTTP endpoint with fixture
        try mockServer.registerFixture(
            endpoint: "/api/plugin/slack",
            method: "GET",
            fixturePath: "HTTP/plugin_response.json"
        )

        // Setup shell command with fixture
        try mockShell.registerCommandWithFixture(
            command: "slack-cli send-message",
            fixturePath: "Shell/cat_config_output.txt",
            exitCode: 0
        )

        // Act - Simulate E2E test scenario

        // Step 1: Fetch data from HTTP API
        let httpExpectation = expectation(description: "HTTP API call")
        var receivedData: Data?

        let url = URL(string: "http://localhost:\(mockServer.port)/api/plugin/slack")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            receivedData = data
            httpExpectation.fulfill()
        }.resume()

        wait(for: [httpExpectation], timeout: 5.0)

        // Step 2: Execute shell command
        let shellResult = try mockShell.execute("slack-cli send-message")

        // Step 3: Store data in database
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                arguments: ["Test", "E2E Test Content", Date(), Date()]
            )
        }

        // Assert
        XCTAssertNotNil(receivedData, "Should receive HTTP response")
        XCTAssertFalse(shellResult.output.isEmpty, "Should execute shell command")

        let itemCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }
        XCTAssertEqual(itemCount, 1, "Should store data in database")
    }

    func testIsolatedTestEnvironment() throws {
        // Arrange - Setup isolated environment
        try mockServer.start()
        try databaseManager.initialize()

        // Act - Run first test scenario
        mockServer.register(endpoint: "/test1", method: "GET", statusCode: 200, responseData: Data())
        mockShell.registerCommand(command: "test1", output: "output1", exitCode: 0)

        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                arguments: ["Test1", "Content1", Date(), Date()]
            )
        }

        // Reset for second test scenario
        mockServer.reset()
        mockShell.reset()

        // Assert - Environment should be clean after reset
        mockServer.register(endpoint: "/test2", method: "GET", statusCode: 200, responseData: Data())
        mockShell.registerCommand(command: "test2", output: "output2", exitCode: 0)

        // Database remains isolated with in-memory instance
        let itemCount = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }
        XCTAssertEqual(itemCount, 1, "Database should maintain state within test")

        // Verify mock server reset
        let requestCount = mockServer.requestCount(for: "/test1", method: "GET")
        XCTAssertEqual(requestCount, 0, "Mock server should be reset")

        // Verify mock shell reset
        XCTAssertThrowsError(
            try mockShell.execute("test1"),
            "Mock shell should not have old registrations"
        )
    }

    // MARK: - Integration: Multi-Step Workflow

    func testMultiStepPluginWorkflow() throws {
        // Arrange
        try mockServer.start()

        // Step 1: Register plugin authentication endpoint
        try mockServer.registerFixture(
            endpoint: "/auth/token",
            method: "POST",
            fixturePath: "HTTP/plugin_response.json"
        )

        // Step 2: Register plugin data fetch endpoint
        mockServer.register(
            endpoint: "/data/messages",
            method: "GET",
            statusCode: 200,
            responseData: """
            {
                "messages": [
                    {"id": 1, "text": "Hello"},
                    {"id": 2, "text": "World"}
                ]
            }
            """.data(using: .utf8)!
        )

        // Step 3: Register shell command for post-processing
        mockShell.registerCommand(
            command: "process-messages",
            output: "Processed 2 messages",
            exitCode: 0
        )

        // Act - Execute workflow
        var authSuccess = false
        var dataFetched = false

        // Authenticate
        let authURL = URL(string: "http://localhost:\(mockServer.port)/auth/token")!
        var authRequest = URLRequest(url: authURL)
        authRequest.httpMethod = "POST"

        let authExpectation = expectation(description: "Auth")
        URLSession.shared.dataTask(with: authRequest) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                authSuccess = true
            }
            authExpectation.fulfill()
        }.resume()

        wait(for: [authExpectation], timeout: 5.0)

        // Fetch data
        let dataURL = URL(string: "http://localhost:\(mockServer.port)/data/messages")!
        let dataExpectation = expectation(description: "Fetch data")

        URLSession.shared.dataTask(with: dataURL) { data, response, error in
            if data != nil {
                dataFetched = true
            }
            dataExpectation.fulfill()
        }.resume()

        wait(for: [dataExpectation], timeout: 5.0)

        // Process with shell
        let processResult = try mockShell.execute("process-messages")

        // Assert
        XCTAssertTrue(authSuccess, "Authentication should succeed")
        XCTAssertTrue(dataFetched, "Data should be fetched")
        XCTAssertEqual(processResult.exitCode, 0, "Processing should succeed")
        XCTAssertTrue(processResult.output.contains("2 messages"), "Should process correct number of messages")
    }

    // MARK: - Integration: Error Handling

    func testErrorHandlingAcrossComponents() throws {
        // Arrange
        try mockServer.start()

        // Setup HTTP error response
        mockServer.register(
            endpoint: "/api/error",
            method: "GET",
            statusCode: 500,
            responseData: """
            {"error": "Internal Server Error"}
            """.data(using: .utf8)!
        )

        // Setup shell command error
        mockShell.registerCommand(
            command: "failing-command",
            output: "",
            exitCode: 1,
            error: "Command failed"
        )

        // Act & Assert - HTTP error
        let url = URL(string: "http://localhost:\(mockServer.port)/api/error")!
        let httpExpectation = expectation(description: "HTTP error")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 500, "Should return error status code")
            }
            httpExpectation.fulfill()
        }.resume()

        wait(for: [httpExpectation], timeout: 5.0)

        // Act & Assert - Shell error
        let shellResult = try mockShell.execute("failing-command")
        XCTAssertEqual(shellResult.exitCode, 1, "Should return error exit code")
        XCTAssertEqual(shellResult.error, "Command failed", "Should capture error message")
    }

    // MARK: - Performance Tests

    func testParallelRequestHandling() throws {
        // Arrange
        try mockServer.start()
        mockServer.register(endpoint: "/api/fast", method: "GET", statusCode: 200, responseData: Data())

        // Act - Send 10 parallel requests
        let expectations = (0..<10).map { expectation(description: "Request \($0)") }
        let url = URL(string: "http://localhost:\(mockServer.port)/api/fast")!

        for expectation in expectations {
            URLSession.shared.dataTask(with: url) { _, _, _ in
                expectation.fulfill()
            }.resume()
        }

        // Assert
        wait(for: expectations, timeout: 10.0)

        let requestCount = mockServer.requestCount(for: "/api/fast", method: "GET")
        XCTAssertEqual(requestCount, 10, "Should handle all parallel requests")
    }
}
