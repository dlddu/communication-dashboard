#if DEBUG
import Foundation

// MARK: - MockURLProtocol
//
// URLSession 요청을 인터셉트하여 미리 등록된 fixture 응답을 반환합니다.
// UI 테스트에서 --ui-testing launch argument를 사용할 때 활성화됩니다.
//
// 사용 예:
//   MockURLProtocol.register(
//       url: URL(string: "https://api.example.com/data")!,
//       response: MockURLProtocol.Response(data: jsonData, statusCode: 200)
//   )

final class MockURLProtocol: URLProtocol {

    // MARK: - Types

    struct Response {
        let data: Data
        let statusCode: Int
        let headers: [String: String]

        init(data: Data, statusCode: Int = 200, headers: [String: String] = [:]) {
            self.data = data
            self.statusCode = statusCode
            self.headers = headers
        }
    }

    // MARK: - Static State

    /// URL → Response 매핑 테이블. 테스트 시작 전에 등록합니다.
    private static var registeredResponses: [URL: Response] = [:]
    private static let lock = NSLock()

    // MARK: - Registration

    /// 특정 URL에 대한 mock 응답을 등록합니다.
    static func register(url: URL, response: Response) {
        lock.lock()
        defer { lock.unlock() }
        registeredResponses[url] = response
    }

    /// 모든 등록된 mock 응답을 초기화합니다.
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        registeredResponses.removeAll()
    }

    /// MockURLProtocol이 적용된 URLSession을 반환합니다.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        lock.lock()
        defer { lock.unlock() }
        return registeredResponses[url] != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: MockURLProtocolError.missingURL)
            return
        }

        MockURLProtocol.lock.lock()
        let mockResponse = MockURLProtocol.registeredResponses[url]
        MockURLProtocol.lock.unlock()

        guard let mockResponse = mockResponse else {
            client?.urlProtocol(
                self,
                didFailWithError: MockURLProtocolError.noRegisteredResponse(url: url)
            )
            return
        }

        // HTTP 응답 생성
        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!

        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mockResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // 정리 작업 없음
    }
}

// MARK: - MockURLProtocolError

enum MockURLProtocolError: LocalizedError {
    case missingURL
    case noRegisteredResponse(url: URL)

    var errorDescription: String? {
        switch self {
        case .missingURL:
            return "요청 URL이 없습니다"
        case .noRegisteredResponse(let url):
            return "등록된 응답이 없습니다: \(url.absoluteString)"
        }
    }
}
#endif
