import SwiftUI

// MARK: - LoginView

/// API 토큰 기반 로그인 뷰.
/// 이메일/비밀번호 필드 없이 API 토큰만으로 인증합니다.
struct LoginView: View {

    // MARK: - Properties

    @StateObject private var viewModel = LoginViewModel()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {
            // 앱 로고 영역
            appLogo

            // 토큰 입력 영역
            tokenField

            // 로그인 버튼
            loginButton

            // 에러 메시지
            errorMessage
        }
        .padding(32)
        .frame(maxWidth: 400)
        .background(AppTheme.surfaceColor)
        .cornerRadius(AppTheme.cornerRadius)
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
        .accessibilityIdentifier("login_view")
    }

    // MARK: - Subviews

    private var appLogo: some View {
        VStack(spacing: 8) {
            Image(systemName: "network")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            Text("CommBoard")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("API 토큰을 입력하여 로그인하세요")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var tokenField: some View {
        SecureField("API 토큰", text: $viewModel.apiToken)
            .textFieldStyle(.roundedBorder)
            .accessibilityIdentifier("api_token_field")
    }

    private var loginButton: some View {
        Button(action: {
            Task {
                await viewModel.authenticate()
            }
        }) {
            Group {
                if viewModel.loginState == .authenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("로그인")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(viewModel.isTokenValid ? Color.accentColor : Color.gray)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isTokenValid || viewModel.loginState == .authenticating)
        .accessibilityIdentifier("login_button")
    }

    @ViewBuilder
    private var errorMessage: some View {
        if case .error(let message) = viewModel.loginState {
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityIdentifier("login_error_message")
        }
    }
}
