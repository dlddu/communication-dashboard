import XCTest
import Foundation
@testable import TestInfrastructure

final class MockHTTPServerTests: XCTestCase {
    var mockServer: MockHTTPServer!

    override func setUp() {
        super.setUp()
        // Use Bundle.module to locate test fixtures
        let fixturesDirectory = Bundle.module.resourceURL!.appendingPathComponent("Fixtures")
        mockServer = MockHTTPServer(fixturesDirectory: fixturesDirectory)
    }

    override func tearDown() {
        mockServer.stop()
        mockServer = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testServerStartsSuccessfully() throws {
        // Act
        try mockServer.start()

        // Assert
        XCTAssertTrue(mockServer.isRunning, "Server should be running after start")
    }

    func testServerStopsSuccessfully() throws {
        // Arrange
        try mockServer.start()

        // Act
        mockServer.stop()

        // Assert
        XCTAssertFalse(mockServer.isRunning, "Server should not be running after stop")
    }

    func testRegisterFixtureResponseForEndpoint() throws {
        // Arrange
        try mockServer.start()
        let fixtureData = """
        {
            "status": "success",
            "data": {
                "message": "Hello from fixture"
            }
        }
        """.data(using: .utf8)!

        // Act
        mockServer.register(
            endpoint: "/api/test",
            method: "GET",
            statusCode: 200,
            responseData: fixtureData,
            headers: ["Content-Type": "application/json"]
        )

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/test")!
        let request = URLRequest(url: url)

        let expectation = expectation(description: "HTTP request")
        URLSession.shared.dataTask(with: request) { data, response, error in
            XCTAssertNil(error, "Should not have error")
            XCTAssertNotNil(data, "Should have response data")

            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200, "Should return status code 200")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    func testLoadFixtureFromFile() throws {
        // Arrange
        try mockServer.start()

        // Act
        try mockServer.registerFixture(
            endpoint: "/api/plugin/test",
            method: "GET",
            fixturePath: "HTTP/plugin_response.json"
        )

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/plugin/test")!
        let request = URLRequest(url: url)

        let expectation = expectation(description: "Fixture request")
        URLSession.shared.dataTask(with: request) { data, response, error in
            XCTAssertNil(error, "Should not have error")
            XCTAssertNotNil(data, "Should load fixture data")

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                XCTAssertNotNil(json["status"], "Fixture should contain status field")
            }

            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    func testRegisterMultipleEndpoints() throws {
        // Arrange
        try mockServer.start()

        // Act
        mockServer.register(
            endpoint: "/api/endpoint1",
            method: "GET",
            statusCode: 200,
            responseData: "Response 1".data(using: .utf8)!
        )

        mockServer.register(
            endpoint: "/api/endpoint2",
            method: "POST",
            statusCode: 201,
            responseData: "Response 2".data(using: .utf8)!
        )

        // Assert - Request endpoint 1
        let url1 = URL(string: "http://localhost:\(mockServer.port)/api/endpoint1")!
        let expectation1 = expectation(description: "Endpoint 1")

        URLSession.shared.dataTask(with: url1) { data, response, error in
            XCTAssertNil(error)
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200)
            }
            expectation1.fulfill()
        }.resume()

        // Assert - Request endpoint 2
        let url2 = URL(string: "http://localhost:\(mockServer.port)/api/endpoint2")!
        var request2 = URLRequest(url: url2)
        request2.httpMethod = "POST"
        let expectation2 = expectation(description: "Endpoint 2")

        URLSession.shared.dataTask(with: request2) { data, response, error in
            XCTAssertNil(error)
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 201)
            }
            expectation2.fulfill()
        }.resume()

        wait(for: [expectation1, expectation2], timeout: 5.0)
    }

    func testRequestCountTracking() throws {
        // Arrange
        try mockServer.start()
        mockServer.register(
            endpoint: "/api/test",
            method: "GET",
            statusCode: 200,
            responseData: Data()
        )

        // Act
        let url = URL(string: "http://localhost:\(mockServer.port)/api/test")!
        let expectation1 = expectation(description: "Request 1")
        let expectation2 = expectation(description: "Request 2")

        URLSession.shared.dataTask(with: url) { _, _, _ in
            expectation1.fulfill()
        }.resume()

        URLSession.shared.dataTask(with: url) { _, _, _ in
            expectation2.fulfill()
        }.resume()

        wait(for: [expectation1, expectation2], timeout: 5.0)

        // Assert
        let count = mockServer.requestCount(for: "/api/test", method: "GET")
        XCTAssertEqual(count, 2, "Should track request count correctly")
    }

    func testCaptureRequestBody() throws {
        // Arrange
        try mockServer.start()
        mockServer.register(
            endpoint: "/api/submit",
            method: "POST",
            statusCode: 200,
            responseData: Data()
        )

        // Act
        let url = URL(string: "http://localhost:\(mockServer.port)/api/submit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyData = "{\"key\":\"value\"}".data(using: .utf8)!
        request.httpBody = bodyData

        let expectation = expectation(description: "POST request")
        URLSession.shared.dataTask(with: request) { _, _, _ in
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)

        // Assert
        let capturedBodies = mockServer.capturedRequestBodies(for: "/api/submit", method: "POST")
        XCTAssertEqual(capturedBodies.count, 1, "Should capture one request body")

        if let captured = capturedBodies.first {
            let jsonString = String(data: captured, encoding: .utf8)
            XCTAssertEqual(jsonString, "{\"key\":\"value\"}", "Should capture correct body data")
        }
    }

    // MARK: - Edge Case Tests

    func testServerCanRestartAfterStop() throws {
        // Arrange
        try mockServer.start()
        mockServer.stop()

        // Act
        try mockServer.start()

        // Assert
        XCTAssertTrue(mockServer.isRunning, "Server should be running after restart")
    }

    func testUnregisteredEndpointReturns404() throws {
        // Arrange
        try mockServer.start()

        // Act
        let url = URL(string: "http://localhost:\(mockServer.port)/nonexistent")!
        let expectation = expectation(description: "404 request")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Assert
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 404, "Should return 404 for unregistered endpoint")
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    func testResetClearsAllRegistrations() throws {
        // Arrange
        try mockServer.start()
        mockServer.register(endpoint: "/api/test", method: "GET", statusCode: 200, responseData: Data())

        // Act
        mockServer.reset()

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/test")!
        let expectation = expectation(description: "After reset")

        URLSession.shared.dataTask(with: url) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 404, "Should return 404 after reset")
            }
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }

    func testSameEndpointDifferentMethods() throws {
        // Arrange
        try mockServer.start()

        // Act
        mockServer.register(endpoint: "/api/resource", method: "GET", statusCode: 200, responseData: "GET data".data(using: .utf8)!)
        mockServer.register(endpoint: "/api/resource", method: "POST", statusCode: 201, responseData: "POST data".data(using: .utf8)!)

        // Assert - GET request
        let url = URL(string: "http://localhost:\(mockServer.port)/api/resource")!
        let expectationGET = expectation(description: "GET request")

        URLSession.shared.dataTask(with: url) { data, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 200)
            }
            if let data = data, let text = String(data: data, encoding: .utf8) {
                XCTAssertEqual(text, "GET data")
            }
            expectationGET.fulfill()
        }.resume()

        // Assert - POST request
        var postRequest = URLRequest(url: url)
        postRequest.httpMethod = "POST"
        let expectationPOST = expectation(description: "POST request")

        URLSession.shared.dataTask(with: postRequest) { data, response, _ in
            if let httpResponse = response as? HTTPURLResponse {
                XCTAssertEqual(httpResponse.statusCode, 201)
            }
            if let data = data, let text = String(data: data, encoding: .utf8) {
                XCTAssertEqual(text, "POST data")
            }
            expectationPOST.fulfill()
        }.resume()

        wait(for: [expectationGET, expectationPOST], timeout: 5.0)
    }

    // MARK: - Error Case Tests

    func testStartThrowsWhenAlreadyRunning() throws {
        // Arrange
        try mockServer.start()

        // Act & Assert
        XCTAssertThrowsError(
            try mockServer.start(),
            "Should throw error when starting already running server"
        ) { error in
            XCTAssertTrue(error is MockHTTPServer.ServerError, "Should throw ServerError")
        }
    }

    func testRegisterThrowsWhenServerNotRunning() {
        // Act & Assert
        XCTAssertThrowsError(
            try mockServer.registerFixture(
                endpoint: "/test",
                method: "GET",
                fixturePath: "test.json"
            ),
            "Should throw error when registering on stopped server"
        ) { error in
            XCTAssertTrue(error is MockHTTPServer.ServerError, "Should throw ServerError")
        }
    }

    func testLoadNonexistentFixtureThrows() throws {
        // Arrange
        try mockServer.start()

        // Act & Assert
        XCTAssertThrowsError(
            try mockServer.registerFixture(
                endpoint: "/test",
                method: "GET",
                fixturePath: "nonexistent.json"
            ),
            "Should throw error when fixture file doesn't exist"
        ) { error in
            XCTAssertTrue(error is MockHTTPServer.FixtureError, "Should throw FixtureError")
        }
    }

    func testDelayedResponse() throws {
        // Arrange
        try mockServer.start()

        // Act
        mockServer.register(
            endpoint: "/api/slow",
            method: "GET",
            statusCode: 200,
            responseData: Data(),
            delay: 0.5
        )

        // Assert
        let url = URL(string: "http://localhost:\(mockServer.port)/api/slow")!
        let startTime = Date()
        let expectation = expectation(description: "Delayed response")

        URLSession.shared.dataTask(with: url) { _, _, _ in
            let elapsedTime = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(elapsedTime, 0.5, "Response should be delayed")
            expectation.fulfill()
        }.resume()

        wait(for: [expectation], timeout: 5.0)
    }
}
