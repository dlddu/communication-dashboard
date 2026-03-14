import Foundation

// MARK: - MockURLResponse

/// MockURLProtocol에 등록할 mock 응답을 정의합니다.
struct MockURLResponse {
    /// HTTP 상태 코드 (기본값: 200)
    let statusCode: Int
    /// 응답 헤더
    let headers: [String: String]
    /// 응답 바디 데이터 (nil이면 빈 응답)
    let body: Data?
    /// 응답 지연 시간 (초, 기본값: 0)
    let delay: TimeInterval

    init(
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        body: Data? = nil,
        delay: TimeInterval = 0
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.delay = delay
    }

    /// JSON 딕셔너리로 응답 바디를 생성하는 편의 초기화입니다.
    init(
        statusCode: Int = 200,
        headers: [String: String] = ["Content-Type": "application/json"],
        json: [String: Any],
        delay: TimeInterval = 0
    ) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        self.init(statusCode: statusCode, headers: headers, body: data, delay: delay)
    }
}

// MARK: - MockURLProtocol

/// URLProtocol을 상속하여 네트워크 요청을 인터셉트하는 테스트용 Mock입니다.
///
/// 사용 예시:
/// ```swift
/// // URL 패턴별 mock 응답 등록
/// MockURLProtocol.register(
///     urlPattern: "https://api.example.com/notifications",
///     response: MockURLResponse(statusCode: 200, body: jsonData)
/// )
///
/// // URLSession에 MockURLProtocol 주입
/// let config = URLSessionConfiguration.ephemeral
/// config.protocolClasses = [MockURLProtocol.self]
/// let session = URLSession(configuration: config)
///
/// // 테스트 종료 후 등록된 mock 제거
/// MockURLProtocol.removeAll()
/// ```
final class MockURLProtocol: URLProtocol {

    // MARK: - 등록된 mock 응답 저장소

    /// URL 패턴(prefix 매칭)을 키로, 응답을 값으로 저장합니다.
    private static var registeredResponses: [String: MockURLResponse] = [:]

    /// 요청 횟수를 URL 패턴별로 추적합니다 (검증용).
    private static var requestCounts: [String: Int] = [:]

    /// thread-safe 접근을 위한 직렬 큐
    private static let queue = DispatchQueue(label: "com.commboard.mockurlprotocol")

    // MARK: - Mock 등록 / 해제

    /// URL 패턴에 해당하는 mock 응답을 등록합니다.
    ///
    /// - Parameters:
    ///   - urlPattern: 요청 URL이 포함해야 하는 패턴 (prefix 또는 포함 문자열)
    ///   - response: 해당 패턴에 반환할 mock 응답
    static func register(urlPattern: String, response: MockURLResponse) {
        queue.sync {
            registeredResponses[urlPattern] = response
        }
    }

    /// 등록된 모든 mock 응답과 요청 카운트를 초기화합니다.
    static func removeAll() {
        queue.sync {
            registeredResponses.removeAll()
            requestCounts.removeAll()
        }
    }

    /// 특정 URL 패턴에 해당하는 mock 응답만 제거합니다.
    static func remove(urlPattern: String) {
        queue.sync {
            registeredResponses.removeValue(forKey: urlPattern)
            requestCounts.removeValue(forKey: urlPattern)
        }
    }

    /// 특정 URL 패턴에 대한 요청 횟수를 반환합니다.
    static func requestCount(for urlPattern: String) -> Int {
        queue.sync {
            requestCounts[urlPattern] ?? 0
        }
    }

    // MARK: - URLProtocol 필수 구현

    /// 이 MockURLProtocol이 해당 요청을 처리할 수 있는지 판단합니다.
    override class func canInit(with request: URLRequest) -> Bool {
        guard let urlString = request.url?.absoluteString else { return false }
        return queue.sync {
            registeredResponses.keys.contains { pattern in
                urlString.contains(pattern)
            }
        }
    }

    /// 요청의 표준 버전을 반환합니다. 변환 없이 그대로 반환합니다.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    /// mock 응답을 반환하여 실제 네트워크 요청을 인터셉트합니다.
    override func startLoading() {
        guard let urlString = request.url?.absoluteString else {
            client?.urlProtocol(self, didFailWithError: MockURLProtocolError.invalidURL)
            return
        }

        // 매칭되는 패턴 탐색
        let (pattern, mockResponse) = MockURLProtocol.queue.sync { () -> (String?, MockURLResponse?) in
            for (pat, resp) in MockURLProtocol.registeredResponses {
                if urlString.contains(pat) {
                    return (pat, resp)
                }
            }
            return (nil, nil)
        }

        guard let matchedPattern = pattern, let response = mockResponse else {
            client?.urlProtocol(self, didFailWithError: MockURLProtocolError.noRegisteredResponse(url: urlString))
            return
        }

        // 요청 횟수 증가
        MockURLProtocol.queue.sync {
            MockURLProtocol.requestCounts[matchedPattern, default: 0] += 1
        }

        // 응답 지연 처리
        let deliverResponse: () -> Void = { [weak self] in
            guard let self = self else { return }

            guard let httpResponse = HTTPURLResponse(
                url: self.request.url!,
                statusCode: response.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: response.headers
            ) else {
                self.client?.urlProtocol(
                    self,
                    didFailWithError: MockURLProtocolError.failedToCreateHTTPResponse
                )
                return
            }

            self.client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)

            if let body = response.body {
                self.client?.urlProtocol(self, didLoad: body)
            }

            self.client?.urlProtocolDidFinishLoading(self)
        }

        if response.delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + response.delay) {
                deliverResponse()
            }
        } else {
            deliverResponse()
        }
    }

    /// 요청 취소 시 호출됩니다. 현재는 별도 처리가 없습니다.
    override func stopLoading() {}
}

// MARK: - MockURLProtocolError

/// MockURLProtocol에서 발생할 수 있는 에러 유형입니다.
enum MockURLProtocolError: Error, LocalizedError {
    case invalidURL
    case noRegisteredResponse(url: String)
    case failedToCreateHTTPResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "요청 URL이 유효하지 않습니다."
        case .noRegisteredResponse(let url):
            return "URL '\(url)'에 등록된 mock 응답이 없습니다."
        case .failedToCreateHTTPResponse:
            return "HTTPURLResponse 생성에 실패했습니다."
        }
    }
}
