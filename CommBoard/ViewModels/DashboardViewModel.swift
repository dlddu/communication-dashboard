import Foundation

// MARK: - DashboardLoadingState

/// 대시보드 로딩 상태를 나타냅니다.
enum DashboardLoadingState: Equatable {
    case loading
    case loaded
    case empty
    case error(message: String)
}

// MARK: - ConnectionStatus

/// WebSocket/API 연결 상태를 나타냅니다.
enum ConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case error
}

// MARK: - DashboardViewModel

/// DashboardView의 상태와 로직을 관리합니다.
/// TitleBar + WidgetGridView + StatusBar를 조합한 메인 화면의 ViewModel입니다.
class DashboardViewModel: ObservableObject {

    // MARK: - Properties

    /// 현재 로딩 상태
    @Published var loadingState: DashboardLoadingState = .loading

    /// 로드된 위젯 레이아웃 목록
    @Published var widgets: [WidgetLayout] = []

    /// 현재 연결 상태
    @Published var connectionStatus: ConnectionStatus = .disconnected

    /// 편집 모드 활성화 여부
    @Published var isEditMode: Bool = false

    /// 앱 이름
    let appName: String = "CommBoard"

    // MARK: - Edit Mode

    /// 편집 모드를 토글합니다.
    func toggleEditMode() {
        isEditMode.toggle()
    }

    // MARK: - Connection Status

    /// 연결 상태를 업데이트합니다.
    func updateConnectionStatus(_ status: ConnectionStatus) {
        connectionStatus = status
    }

    // MARK: - Loading State

    /// 로딩 상태를 비동기적으로 설정합니다.
    @MainActor
    func setLoadingState(_ state: DashboardLoadingState) async {
        loadingState = state
    }

    // MARK: - Retry

    /// 에러 상태에서 재시도합니다. 상태를 loading으로 초기화합니다.
    @MainActor
    func retry() async {
        loadingState = .loading
    }
}
