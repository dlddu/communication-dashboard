import Foundation

/// Mock HTTP server using URLProtocol for intercepting requests
public class MockHTTPServer {
    public enum ServerError: Error {
        case alreadyRunning
        case notRunning
    }

    public enum FixtureError: Error {
        case fixtureNotFound(String)
        case loadFailed(String)
    }

    private struct EndpointRegistration {
        let method: String
        let statusCode: Int
        let responseData: Data
        let headers: [String: String]
        let delay: TimeInterval
    }

    private struct RequestRecord {
        let endpoint: String
        let method: String
        let body: Data?
        let timestamp: Date
    }

    private var isServerRunning = false
    private var registeredEndpoints: [String: EndpointRegistration] = [:]
    private var requestHistory: [String: [RequestRecord]] = [:]
    private let fixtureLoader = FixtureLoader()

    public var isRunning: Bool {
        return isServerRunning
    }

    public var port: Int {
        // Mock server uses URLProtocol, so port is virtual
        return 8080
    }

    public init() {}

    // MARK: - Server Control

    /// Start the mock HTTP server
    public func start() throws {
        guard !isServerRunning else {
            throw ServerError.alreadyRunning
        }

        // Register the custom URLProtocol
        MockHTTPURLProtocol.server = self
        URLProtocol.registerClass(MockHTTPURLProtocol.self)

        isServerRunning = true
    }

    /// Stop the mock HTTP server
    public func stop() {
        if isServerRunning {
            URLProtocol.unregisterClass(MockHTTPURLProtocol.self)
            MockHTTPURLProtocol.server = nil
            isServerRunning = false
        }
    }

    /// Reset all registrations and history
    public func reset() {
        registeredEndpoints.removeAll()
        requestHistory.removeAll()
    }

    // MARK: - Endpoint Registration

    /// Register an endpoint with response data
    public func register(
        endpoint: String,
        method: String,
        statusCode: Int,
        responseData: Data,
        headers: [String: String] = [:],
        delay: TimeInterval = 0
    ) {
        let key = makeKey(endpoint: endpoint, method: method)
        registeredEndpoints[key] = EndpointRegistration(
            method: method,
            statusCode: statusCode,
            responseData: responseData,
            headers: headers,
            delay: delay
        )
    }

    /// Register an endpoint with fixture file
    public func registerFixture(
        endpoint: String,
        method: String,
        fixturePath: String,
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        delay: TimeInterval = 0
    ) throws {
        guard isServerRunning else {
            throw ServerError.notRunning
        }

        do {
            let data = try fixtureLoader.loadFixture(path: fixturePath)
            register(
                endpoint: endpoint,
                method: method,
                statusCode: statusCode,
                responseData: data,
                headers: headers,
                delay: delay
            )
        } catch {
            throw FixtureError.fixtureNotFound("Failed to load fixture: \(fixturePath)")
        }
    }

    // MARK: - Request Tracking

    /// Get request count for an endpoint
    public func requestCount(for endpoint: String, method: String) -> Int {
        let key = makeKey(endpoint: endpoint, method: method)
        return requestHistory[key]?.count ?? 0
    }

    /// Get captured request bodies for an endpoint
    public func capturedRequestBodies(for endpoint: String, method: String) -> [Data] {
        let key = makeKey(endpoint: endpoint, method: method)
        return requestHistory[key]?.compactMap { $0.body } ?? []
    }

    // MARK: - Internal Methods

    fileprivate func handleRequest(
        endpoint: String,
        method: String,
        body: Data?
    ) -> (statusCode: Int, data: Data, headers: [String: String], delay: TimeInterval)? {
        // Record request
        let key = makeKey(endpoint: endpoint, method: method)
        let record = RequestRecord(
            endpoint: endpoint,
            method: method,
            body: body,
            timestamp: Date()
        )
        requestHistory[key, default: []].append(record)

        // Find registration
        guard let registration = registeredEndpoints[key] else {
            return (statusCode: 404, data: Data(), headers: [:], delay: 0)
        }

        return (
            statusCode: registration.statusCode,
            data: registration.responseData,
            headers: registration.headers,
            delay: registration.delay
        )
    }

    private func makeKey(endpoint: String, method: String) -> String {
        return "\(method):\(endpoint)"
    }
}

// MARK: - URLProtocol Implementation

private class MockHTTPURLProtocol: URLProtocol {
    static weak var server: MockHTTPServer?

    override class func canInit(with request: URLRequest) -> Bool {
        // Only handle requests when server is set
        return server != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let server = MockHTTPURLProtocol.server,
              let url = request.url,
              let method = request.httpMethod else {
            client?.urlProtocol(self, didFailWithError: NSError(
                domain: "MockHTTPServer",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Server not configured"]
            ))
            return
        }

        // Extract endpoint path
        let endpoint = url.path

        // Get request body
        let body = request.httpBody ?? request.httpBodyStream.flatMap { stream in
            var data = Data()
            stream.open()
            defer { stream.close() }

            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            while stream.hasBytesAvailable {
                let bytesRead = stream.read(buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data.append(buffer, count: bytesRead)
                }
            }
            return data
        }

        // Handle request
        guard let response = server.handleRequest(endpoint: endpoint, method: method, body: body) else {
            // Should not happen, but handle gracefully
            sendResponse(statusCode: 500, data: Data(), headers: [:], delay: 0)
            return
        }

        sendResponse(
            statusCode: response.statusCode,
            data: response.data,
            headers: response.headers,
            delay: response.delay
        )
    }

    override func stopLoading() {
        // Nothing to clean up
    }

    private func sendResponse(statusCode: Int, data: Data, headers: [String: String], delay: TimeInterval) {
        // Simulate delay if specified
        if delay > 0 {
            Thread.sleep(forTimeInterval: delay)
        }

        guard let url = request.url else { return }

        // Create HTTP response
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
