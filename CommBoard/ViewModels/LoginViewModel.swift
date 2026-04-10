import Foundation

// MARK: - LoginState

/// 로그인 상태를 나타냅니다.
enum LoginState: Equatable {
    case idle
    case authenticating
    case authenticated
    case error(message: String)
}

// MARK: - LoginViewModel

/// LoginView의 상태와 로직을 관리합니다.
/// API 토큰 기반 인증을 사용하며, 이메일/비밀번호 필드를 사용하지 않습니다.
class LoginViewModel: ObservableObject {

    // MARK: - Properties

    /// API 토큰 입력값
    @Published var apiToken: String = ""

    /// 현재 로그인 상태
    @Published var loginState: LoginState = .idle

    // MARK: - Validation

    /// API 토큰이 유효한지 검사합니다.
    var isTokenValid: Bool {
        !apiToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// API 토큰으로 인증을 시도합니다.
    @MainActor
    func authenticate() async {
        guard isTokenValid else {
            loginState = .error(message: "API 토큰을 입력해주세요")
            return
        }
        loginState = .authenticating
    }

    /// 로그인 상태를 초기화합니다.
    @MainActor
    func reset() async {
        apiToken = ""
        loginState = .idle
    }
}
