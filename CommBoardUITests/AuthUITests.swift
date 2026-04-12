import XCTest

// MARK: - AuthUITests
//
// 관련 이슈: DLD-983 (AuthUITests → E2E 마이그레이션)
//           DLD-985 (test_loginScreen_displaysAppIcon)
//
// 앱 실행 시 초기 화면(로그인 화면)의 UI 요소를 검증합니다.
// 앱 아이콘 이미지가 정상적으로 표시되는지 확인합니다.

final class AuthUITests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Login Screen Tests

    /// 앱 실행 후 초기 화면(로그인 화면)에 앱 아이콘 이미지가 표시되어야 합니다.
    func test_loginScreen_displaysAppIcon() {
        // Arrange & Act
        launchApp()

        // 메인 윈도우가 표시될 때까지 대기
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)
        XCTAssertTrue(windowExists, "메인 윈도우가 표시되어야 합니다")

        // Assert: 초기 화면에 앱 아이콘 이미지 요소가 존재하는지 확인
        let appIcon = app.images.firstMatch
        let iconExists = appIcon.waitForExistence(timeout: 10.0)
        XCTAssertTrue(iconExists, "초기 화면에 앱 아이콘 이미지가 표시되어야 합니다")
    }
}
