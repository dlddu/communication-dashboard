import XCTest

// MARK: - SmokeTests
//
// 앱의 기본 실행 여부를 검증합니다.
// 메인 윈도우가 표시되는지, UI 기본 요소가 접근 가능한지 확인합니다.

final class SmokeTests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - App Launch Tests

    /// 앱 실행 후 메인 윈도우가 표시되어야 합니다.
    func testLaunch_ShowsMainWindow() {
        // Arrange & Act
        launchApp()

        // Assert: 메인 윈도우가 존재하는지 확인
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "앱 실행 후 메인 윈도우가 표시되어야 합니다"
        )
    }

    /// mock 모드(--ui-testing)로 실행해도 메인 윈도우가 표시되어야 합니다.
    func testLaunch_WithMockMode_ShowsMainWindow() {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: mock 모드에서도 메인 윈도우가 정상 표시되어야 합니다
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "--ui-testing 실행 시에도 메인 윈도우가 표시되어야 합니다"
        )
    }

    /// 앱 실행 후 윈도우가 최소 1개 이상 존재해야 합니다.
    func testLaunch_HasAtLeastOneWindow() {
        // Arrange & Act
        launchApp()

        // Assert
        let mainWindow = app.windows.firstMatch
        _ = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertGreaterThanOrEqual(
            app.windows.count,
            1,
            "앱 실행 후 최소 1개의 윈도우가 존재해야 합니다"
        )
    }

    /// 앱 실행 후 메인 윈도우가 화면에 보이는 상태여야 합니다.
    func testLaunch_MainWindowIsHittable() {
        // Arrange & Act
        launchApp()

        // Assert
        let mainWindow = app.windows.firstMatch
        let exists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(exists, "메인 윈도우가 존재해야 합니다")
        XCTAssertTrue(
            mainWindow.isHittable,
            "메인 윈도우가 hittable 상태여야 합니다"
        )
    }

    // MARK: - Screenshot Test

    /// 앱 실행 화면 스크린샷을 XCTAttachment로 저장합니다.
    func testLaunch_AttachesScreenshot() {
        // Arrange & Act
        launchApp()

        // Assert
        let mainWindow = app.windows.firstMatch
        _ = mainWindow.waitForExistence(timeout: 10.0)

        // 스크린샷 첨부
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "App Launch Screenshot"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTAssertTrue(
            mainWindow.exists,
            "스크린샷 첨부 시 메인 윈도우가 존재해야 합니다"
        )
    }
}
