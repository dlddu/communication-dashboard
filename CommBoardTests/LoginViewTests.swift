import XCTest
@testable import CommBoard

// MARK: - LoginViewTests
//
// LoginView의 ViewModel 로직을 검증합니다.
// LoginView는 API 토큰 기반 인증을 사용하며,
// 이메일/비밀번호 필드를 사용하지 않습니다.
//
// 검증 대상:
//   - LoginViewModel에 이메일/비밀번호 속성이 없는지 확인
//   - API 토큰 기반 인증 흐름
//   - 토큰 유효성 검사
//   - 로그인 상태 전환 로직

final class LoginViewTests: XCTestCase {

    // MARK: - Properties

    var sut: LoginViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = LoginViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - No Email/Password Fields Test

    func testLoginView_NoEmailPasswordFields() {
        // Arrange & Act
        let mirror = Mirror(reflecting: sut!)

        let propertyNames = mirror.children.compactMap { $0.label }

        // Assert - 이메일/비밀번호 관련 속성이 없어야 합니다
        let emailRelatedNames = propertyNames.filter {
            $0.lowercased().contains("email")
        }
        let passwordRelatedNames = propertyNames.filter {
            $0.lowercased().contains("password")
        }

        XCTAssertTrue(
            emailRelatedNames.isEmpty,
            "LoginViewModel에 이메일 관련 속성이 없어야 합니다. 발견된 속성: \(emailRelatedNames)"
        )
        XCTAssertTrue(
            passwordRelatedNames.isEmpty,
            "LoginViewModel에 비밀번호 관련 속성이 없어야 합니다. 발견된 속성: \(passwordRelatedNames)"
        )
    }

    // MARK: - Initialization Tests

    func testInitialization_DefaultState_IsIdle() {
        // Assert
        XCTAssertEqual(
            sut.loginState,
            .idle,
            "초기 상태는 idle이어야 합니다"
        )
    }

    func testInitialization_DefaultToken_IsEmpty() {
        // Assert
        XCTAssertTrue(
            sut.apiToken.isEmpty,
            "초기 API 토큰은 비어있어야 합니다"
        )
    }

    // MARK: - Token Validation Tests

    func testIsTokenValid_WhenEmpty_IsFalse() {
        // Arrange
        sut.apiToken = ""

        // Assert
        XCTAssertFalse(
            sut.isTokenValid,
            "빈 토큰은 유효하지 않아야 합니다"
        )
    }

    func testIsTokenValid_WhenWhitespaceOnly_IsFalse() {
        // Arrange
        sut.apiToken = "   "

        // Assert
        XCTAssertFalse(
            sut.isTokenValid,
            "공백만 있는 토큰은 유효하지 않아야 합니다"
        )
    }

    func testIsTokenValid_WhenHasValue_IsTrue() {
        // Arrange
        sut.apiToken = "sk-test-token-12345"

        // Assert
        XCTAssertTrue(
            sut.isTokenValid,
            "값이 있는 토큰은 유효해야 합니다"
        )
    }

    // MARK: - Authentication Tests

    func testAuthenticate_WhenTokenEmpty_SetsErrorState() async {
        // Arrange
        sut.apiToken = ""

        // Act
        await sut.authenticate()

        // Assert
        if case .error(let message) = sut.loginState {
            XCTAssertEqual(message, "API 토큰을 입력해주세요", "에러 메시지가 올바르게 설정되어야 합니다")
        } else {
            XCTFail("빈 토큰으로 인증 시 error 상태여야 합니다")
        }
    }

    func testAuthenticate_WhenTokenValid_SetsAuthenticatingState() async {
        // Arrange
        sut.apiToken = "sk-valid-token"

        // Act
        await sut.authenticate()

        // Assert
        XCTAssertEqual(
            sut.loginState,
            .authenticating,
            "유효한 토큰으로 인증 시 authenticating 상태여야 합니다"
        )
    }

    // MARK: - Reset Tests

    func testReset_ClearsTokenAndState() async {
        // Arrange
        sut.apiToken = "sk-some-token"
        await sut.authenticate()

        // Act
        await sut.reset()

        // Assert
        XCTAssertTrue(sut.apiToken.isEmpty, "리셋 후 토큰이 비어있어야 합니다")
        XCTAssertEqual(sut.loginState, .idle, "리셋 후 상태가 idle이어야 합니다")
    }

    // MARK: - Login State Equality Tests

    func testLoginState_IdleEqualsIdle() {
        // Assert
        XCTAssertEqual(LoginState.idle, LoginState.idle)
    }

    func testLoginState_ErrorWithSameMessage_AreEqual() {
        // Assert
        XCTAssertEqual(
            LoginState.error(message: "test"),
            LoginState.error(message: "test")
        )
    }

    func testLoginState_ErrorWithDifferentMessage_AreNotEqual() {
        // Assert
        XCTAssertNotEqual(
            LoginState.error(message: "a"),
            LoginState.error(message: "b")
        )
    }
}
