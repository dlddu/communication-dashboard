import SwiftUI

// MARK: - DashboardView

/// 대시보드 메인 뷰.
/// TitleBar + WidgetGridView + StatusBar를 조합한 메인 화면입니다.
struct DashboardView: View {

    // MARK: - Properties

    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var gridViewModel = WidgetGridViewModel()
    @StateObject private var statusBarViewModel = StatusBarViewModel()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀 바
            titleBar

            // 위젯 그리드
            WidgetGridView(gridViewModel: gridViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 상태바
            StatusBar(viewModel: statusBarViewModel)
        }
        .background(Color(hex: "#1a1a2e"))
        .onAppear {
            loadMockWidgets()
            setupMockStatusBar()
        }
    }

    // MARK: - Subviews

    private var titleBar: some View {
        HStack {
            Text(dashboardViewModel.appName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // 편집 모드 토글 버튼
            Button(action: {
                dashboardViewModel.toggleEditMode()
            }) {
                Text(dashboardViewModel.isEditMode ? "완료" : "편집")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "#16213e"))
    }

    // MARK: - Private

    /// mock 모드 또는 초기 실행 시 위젯 목록을 설정합니다.
    private func loadMockWidgets() {
        let mockLayouts: [WidgetLayout] = [
            WidgetLayout(pluginId: "slack", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(pluginId: "github", positionX: 1, positionY: 0, size: "medium", order: 1),
            WidgetLayout(pluginId: "jira", positionX: 2, positionY: 0, size: "large", order: 2),
        ]
        gridViewModel.updateWidgets(mockLayouts)
        dashboardViewModel.widgets = mockLayouts
    }

    /// 상태바 초기값을 설정합니다.
    private func setupMockStatusBar() {
        statusBarViewModel.updateLastSync(Date())
    }
}
