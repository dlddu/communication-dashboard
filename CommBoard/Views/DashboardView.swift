import SwiftUI

// MARK: - DashboardView

/// 대시보드 메인 뷰.
/// TitleBar + WidgetGridView + StatusBar를 조합한 메인 화면입니다.
struct DashboardView: View {

    // MARK: - Properties

    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var gridViewModel = WidgetGridViewModel()
    @StateObject private var statusBarViewModel = StatusBarViewModel()
    @StateObject private var containerViewModel = WidgetContainerViewModel()

    @State private var editModeViewModel: EditModeViewModel? = nil

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 타이틀 바
            titleBar

            // 메인 콘텐츠 (로딩 상태에 따라 분기)
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 상태바
            StatusBar(viewModel: statusBarViewModel)
        }
        .background(AppTheme.backgroundColor)
        .onAppear {
            loadWidgets()
            setupStatusBar()
        }
    }

    // MARK: - Subviews

    private var titleBar: some View {
        HStack {
            Text(dashboardViewModel.appName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // 연결 상태 배지
            ConnectionStatusBadge(status: dashboardViewModel.connectionStatus)

            Spacer()

            // 설정 버튼
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("settings_button")

            // 편집 모드 토글 버튼
            Button(action: {
                if dashboardViewModel.isEditMode {
                    // 편집 모드 종료 시 저장
                    if let vm = editModeViewModel {
                        Task {
                            try? await vm.saveAndExit()
                            // 편집 내용을 그리드에 반영
                            gridViewModel.updateWidgets(vm.editingWidgets)
                            dashboardViewModel.widgets = vm.editingWidgets
                            dashboardViewModel.toggleEditMode()
                            editModeViewModel = nil
                        }
                    } else {
                        dashboardViewModel.toggleEditMode()
                    }
                } else {
                    // 편집 모드 진입 시 EditModeViewModel 생성
                    let allPluginIds = ["slack", "github", "jira", "notion", "figma"]
                    editModeViewModel = EditModeViewModel(
                        widgets: dashboardViewModel.widgets,
                        allPluginIds: allPluginIds,
                        dbManager: (try? DatabaseManager(inMemory: true)) ?? (try! DatabaseManager(inMemory: true))
                    )
                    dashboardViewModel.toggleEditMode()
                }
            }) {
                Text(dashboardViewModel.isEditMode ? "완료" : "편집")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("edit_mode_button")
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.vertical, AppTheme.titleBarVerticalPadding)
        .background(AppTheme.surfaceColor)
    }

    /// 로딩 상태에 따라 메인 콘텐츠를 분기합니다.
    @ViewBuilder
    private var mainContent: some View {
        if dashboardViewModel.isEditMode, let editVM = editModeViewModel {
            // 편집 모드 뷰
            EditModeView(
                viewModel: editVM,
                containerViewModel: containerViewModel,
                onDone: {
                    try? await editVM.saveAndExit()
                    gridViewModel.updateWidgets(editVM.editingWidgets)
                    dashboardViewModel.widgets = editVM.editingWidgets
                    dashboardViewModel.toggleEditMode()
                    editModeViewModel = nil
                }
            )
        } else {
            switch dashboardViewModel.loadingState {
            case .loading:
                loadingView
            case .loaded:
                WidgetGridView(gridViewModel: gridViewModel, containerViewModel: containerViewModel)
            case .empty:
                emptyView
            case .error(let message):
                errorView(message: message)
            }
        }
    }

    /// 로딩 중 스켈레톤 UI
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("위젯을 불러오는 중...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("dashboard_loading")
    }

    /// 데이터 없음 UI
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("표시할 위젯이 없습니다")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("dashboard_empty")
    }

    /// 에러 UI (재시도 버튼 포함)
    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
            Button(action: {
                Task {
                    await dashboardViewModel.retry()
                    loadWidgets()
                }
            }) {
                Text("재시도")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.borderColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dashboard_retry_button")
        }
        .accessibilityIdentifier("dashboard_error")
    }

    // MARK: - Private

    /// widget_layout 테이블에서 위젯 레이아웃을 로드합니다.
    /// DB 연동 실패 시 mock 데이터로 폴백합니다.
    private func loadWidgets() {
        do {
            let dbManager = try DatabaseManager(inMemory: true)
            // DB에 기본 위젯이 없으면 seed 데이터 삽입
            let layouts = try dbManager.fetchWidgetLayouts()
            if layouts.isEmpty {
                seedDefaultWidgets(dbManager: dbManager)
                let seededLayouts = try dbManager.fetchWidgetLayouts()
                applyWidgets(seededLayouts)
            } else {
                applyWidgets(layouts)
            }
        } catch {
            loadMockWidgets()
        }
    }

    /// DB에 기본 위젯 레이아웃을 삽입합니다.
    private func seedDefaultWidgets(dbManager: DatabaseManager) {
        let defaults: [WidgetLayout] = [
            WidgetLayout(pluginId: "slack", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(pluginId: "github", positionX: 1, positionY: 0, size: "medium", order: 1),
            WidgetLayout(pluginId: "jira", positionX: 2, positionY: 0, size: "large", order: 2),
        ]
        for layout in defaults {
            try? dbManager.insertWidgetLayout(layout)
        }
    }

    /// 위젯 레이아웃을 뷰모델에 적용합니다.
    private func applyWidgets(_ layouts: [WidgetLayout]) {
        gridViewModel.updateWidgets(layouts)
        dashboardViewModel.widgets = layouts
        Task {
            await dashboardViewModel.setLoadingState(layouts.isEmpty ? .empty : .loaded)
        }
    }

    /// DB 실패 시 mock 데이터로 폴백합니다.
    private func loadMockWidgets() {
        let mockLayouts: [WidgetLayout] = [
            WidgetLayout(pluginId: "slack", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(pluginId: "github", positionX: 1, positionY: 0, size: "medium", order: 1),
            WidgetLayout(pluginId: "jira", positionX: 2, positionY: 0, size: "large", order: 2),
        ]
        gridViewModel.updateWidgets(mockLayouts)
        dashboardViewModel.widgets = mockLayouts
        Task {
            await dashboardViewModel.setLoadingState(.loaded)
        }
    }

    /// 상태바 초기값을 설정합니다.
    private func setupStatusBar() {
        statusBarViewModel.updateLastSync(Date())
        statusBarViewModel.updatePollingIntervals([
            "slack": 60,
            "github": 120,
            "jira": 300,
        ])
    }
}

// MARK: - ConnectionStatusBadge

/// TitleBar에 표시되는 연결 상태 배지 뷰.
struct ConnectionStatusBadge: View {

    let status: ConnectionStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(badgeColor)
                .frame(width: 8, height: 8)

            Text(badgeText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityIdentifier("connection_status_badge")
    }

    private var badgeColor: Color {
        switch status {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }

    private var badgeText: String {
        switch status {
        case .connected:
            return "연결됨"
        case .connecting:
            return "연결 중"
        case .disconnected:
            return "연결 안 됨"
        case .error:
            return "연결 오류"
        }
    }
}
