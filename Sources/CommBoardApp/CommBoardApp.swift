import SwiftUI

/// CommBoard macOS 앱의 진입점입니다.
///
/// 이 타겟은 CommBoard 라이브러리를 기반으로 하는 실행 가능한 macOS 앱입니다.
/// 플러그인 관리, 알림 수집, 위젯 레이아웃 기능은 CommBoard 라이브러리에 구현되어 있습니다.
@main
struct CommBoardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
