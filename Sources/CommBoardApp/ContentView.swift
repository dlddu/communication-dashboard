import SwiftUI

/// CommBoard 앱의 기본 콘텐츠 뷰입니다.
///
/// 앱의 메인 화면을 구성합니다. 향후 플러그인 목록, 알림 피드,
/// 위젯 대시보드 등의 기능이 이 뷰를 기반으로 확장됩니다.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("CommBoard에 오신 것을 환영합니다")
                .font(.title2)
                .fontWeight(.semibold)

            Text("플러그인과 알림을 한 곳에서 관리하세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}
