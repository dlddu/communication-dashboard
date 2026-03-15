import XCTest

// MARK: - UITestBase
//
// 모든 UI 테스트의 공통 베이스 클래스입니다.
// setUp / tearDown에서 공통 초기화 및 정리를 처리합니다.

class UITestBase: XCTestCase {

    // MARK: - Properties

    /// 테스트 대상 앱 인스턴스
    var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() async throws {
        app = nil
        try await super.tearDown()
    }

    // MARK: - Launch Helpers

    /// 기본 launch argument 없이 앱을 실행합니다.
    func launchApp() {
        app.launch()
    }

    /// --ui-testing launch argument를 포함하여 mock 모드로 앱을 실행합니다.
    func launchAppInMockMode(
        additionalArguments: [String] = [],
        additionalEnvironment: [String: String] = [:]
    ) {
        app.launchArguments = ["--ui-testing"] + additionalArguments
        for (key, value) in additionalEnvironment {
            app.launchEnvironment[key] = value
        }
        app.launch()
    }

    // MARK: - Wait Helpers

    /// 지정된 요소가 나타날 때까지 대기합니다.
    @discardableResult
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 10.0,
        failMessage: String? = nil
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists, let message = failMessage {
            XCTFail(message)
        }
        return exists
    }
}
