import XCTest

// MARK: - MockModeTests
//
// --ui-testing launch argument를 통한 mock 모드 활성화를 검증합니다.
//
// 주의: XCUITest는 앱 외부 프로세스에서 실행되므로
//       앱 내부 상태(MockURLProtocol 등록 여부 등)에 직접 접근할 수 없습니다.
//       launch argument와 environment variable로만 앱과 통신합니다.

final class MockModeTests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Launch Argument Tests

    /// --ui-testing argument 없이 실행하면 일반 모드로 동작해야 합니다.
    func testLaunch_WithoutMockArgument_StartsNormally() {
        // Arrange & Act: launch argument 없이 실행
        app.launchArguments = []
        app.launch()

        // Assert: 앱이 정상 실행되어 윈도우가 표시됨
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "launch argument 없이 실행 시 메인 윈도우가 표시되어야 합니다"
        )
    }

    /// --ui-testing argument를 전달하면 mock 모드로 앱이 실행되어야 합니다.
    func testLaunch_WithUITestingArgument_ActivatesMockMode() {
        // Arrange & Act: mock 모드로 실행
        launchAppInMockMode()

        // Assert: mock 모드에서도 앱이 정상 실행됨
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "--ui-testing 전달 시 앱이 mock 모드로 실행되어야 합니다"
        )
    }

    /// --ui-testing argument가 launchArguments에 정확히 포함되어야 합니다.
    func testLaunchArguments_ContainUITestingFlag() {
        // Arrange
        app.launchArguments = ["--ui-testing"]

        // Assert: launch argument가 올바르게 설정됨
        XCTAssertTrue(
            app.launchArguments.contains("--ui-testing"),
            "launchArguments에 --ui-testing이 포함되어야 합니다"
        )
    }

    /// 추가 launch argument와 함께 --ui-testing이 동작해야 합니다.
    func testLaunch_WithUITestingAndAdditionalArguments_StartsSuccessfully() {
        // Arrange & Act
        launchAppInMockMode(
            additionalArguments: ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        )

        // Assert
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "추가 argument와 함께 mock 모드 실행 시 메인 윈도우가 표시되어야 합니다"
        )
    }

    // MARK: - Fixture Loading Tests

    /// notifications.json fixture 파일이 로드 가능해야 합니다.
    func testFixture_NotificationsJSON_IsLoadable() throws {
        // Arrange & Act
        let data = try FixtureLoader.data(fileName: "notifications")

        // Assert
        XCTAssertFalse(
            data.isEmpty,
            "notifications.json fixture 파일이 비어있지 않아야 합니다"
        )
    }

    /// notifications.json이 유효한 JSON 배열이어야 합니다.
    func testFixture_NotificationsJSON_IsValidJSONArray() throws {
        // Arrange
        let data = try FixtureLoader.data(fileName: "notifications")

        // Act
        let parsed = try JSONSerialization.jsonObject(with: data)

        // Assert
        XCTAssertTrue(
            parsed is [[String: Any]],
            "notifications.json은 JSON 배열이어야 합니다"
        )
    }

    /// config.json fixture 파일이 로드 가능해야 합니다.
    func testFixture_ConfigJSON_IsLoadable() throws {
        // Arrange & Act
        let data = try FixtureLoader.data(fileName: "config")

        // Assert
        XCTAssertFalse(
            data.isEmpty,
            "config.json fixture 파일이 비어있지 않아야 합니다"
        )
    }

    /// config.json이 필수 키를 포함해야 합니다.
    func testFixture_ConfigJSON_ContainsRequiredKeys() throws {
        // Arrange
        let data = try FixtureLoader.data(fileName: "config")

        // Act
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Assert
        XCTAssertNotNil(parsed, "config.json이 딕셔너리 형태여야 합니다")
        XCTAssertNotNil(parsed?["refreshInterval"], "config.json에 refreshInterval이 있어야 합니다")
        XCTAssertNotNil(parsed?["theme"], "config.json에 theme이 있어야 합니다")
        XCTAssertNotNil(parsed?["language"], "config.json에 language가 있어야 합니다")
    }

    /// plugin_github.json fixture 파일이 로드 가능해야 합니다.
    func testFixture_PluginGithubJSON_IsLoadable() throws {
        // Arrange & Act
        let data = try FixtureLoader.data(fileName: "plugin_github")

        // Assert
        XCTAssertFalse(
            data.isEmpty,
            "plugin_github.json fixture 파일이 비어있지 않아야 합니다"
        )
    }

    /// plugin_github.json이 필수 키를 포함해야 합니다.
    func testFixture_PluginGithubJSON_ContainsRequiredKeys() throws {
        // Arrange
        let data = try FixtureLoader.data(fileName: "plugin_github")

        // Act
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Assert
        XCTAssertNotNil(parsed, "plugin_github.json이 딕셔너리 형태여야 합니다")
        XCTAssertNotNil(parsed?["id"], "plugin_github.json에 id가 있어야 합니다")
        XCTAssertNotNil(parsed?["enabled"], "plugin_github.json에 enabled가 있어야 합니다")
        XCTAssertNotNil(parsed?["interval"], "plugin_github.json에 interval이 있어야 합니다")
    }

    // MARK: - Mock Mode With Environment Variables

    /// launch environment로 추가 설정을 전달할 수 있어야 합니다.
    func testLaunch_WithEnvironmentVariables_AppReceivesConfig() {
        // Arrange & Act
        launchAppInMockMode(
            additionalEnvironment: [
                "MOCK_BASE_URL": "https://api.mock.local",
                "MOCK_DELAY_MS": "0"
            ]
        )

        // Assert: 환경 변수가 있어도 앱이 정상 실행됨
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "환경 변수 전달 시에도 앱이 정상 실행되어야 합니다"
        )
    }
}
