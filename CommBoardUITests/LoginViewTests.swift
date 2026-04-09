import XCTest

// MARK: - LoginViewTests
//
// 앱 실행 시 로그인 화면(이메일/비밀번호 입력 필드)이
// 표시되지 않는지 검증합니다.
// CommBoard는 인증 없이 바로 대시보드를 표시해야 합니다.

final class LoginViewTests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Login View Absence Tests

    /// 앱 실행 시 이메일/비밀번호 입력 필드가 표시되지 않아야 합니다.
    func testLoginView_NoEmailPasswordFields() {
        // Arrange & Act
        launchApp()

        // 메인 윈도우가 표시될 때까지 대기
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)
        XCTAssertTrue(windowExists, "메인 윈도우가 표시되어야 합니다")

        // Assert: 이메일 입력 필드가 존재하지 않아야 합니다
        let emailFields = app.textFields.matching(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'email' OR identifier CONTAINS[c] 'email'")
        )
        XCTAssertEqual(
            emailFields.count,
            0,
            "앱 실행 시 이메일 입력 필드가 표시되지 않아야 합니다"
        )

        // Assert: 비밀번호 입력 필드가 존재하지 않아야 합니다
        let passwordFields = app.secureTextFields.matching(
            NSPredicate(format: "placeholderValue CONTAINS[c] 'password' OR identifier CONTAINS[c] 'password'")
        )
        XCTAssertEqual(
            passwordFields.count,
            0,
            "앱 실행 시 비밀번호 입력 필드가 표시되지 않아야 합니다"
        )
    }
}
