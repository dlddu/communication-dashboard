import SwiftUI

@main
struct CommBoardApp: App {

    // MARK: - Mock Mode

    /// --ui-testing launch argument가 전달되면 mock 모드로 동작합니다.
    /// XCUITest는 별도 프로세스이므로 launch argument를 통해서만 앱과 통신합니다.
    private let isMockMode: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("--ui-testing")
        #else
        return false
        #endif
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    configureMockModeIfNeeded()
                }
        }
    }

    // MARK: - Private

    private func configureMockModeIfNeeded() {
        #if DEBUG
        guard isMockMode else { return }

        // MockURLProtocol을 URLSession.shared에 등록하여
        // 앱 전체의 네트워크 요청을 인터셉트합니다.
        URLProtocol.registerClass(MockURLProtocol.self)
        #endif
    }
}
