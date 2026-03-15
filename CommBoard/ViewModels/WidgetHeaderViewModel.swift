import Foundation

// MARK: - WidgetHeaderViewModel

/// WidgetHeader의 표시 로직을 관리합니다.
/// 위젯 카드 상단에 위치하며 아이콘, 제목, unread 배지, 새로고침 버튼을 담당합니다.
class WidgetHeaderViewModel: ObservableObject {

    // MARK: - Properties

    /// 플러그인 식별자
    let pluginId: String

    /// 위젯 제목
    @Published var title: String

    /// SF Symbols 아이콘 이름
    @Published var icon: String

    /// 읽지 않은 항목 수
    @Published var unreadCount: Int

    /// 새로고침 진행 중 여부
    @Published var isRefreshing: Bool = false

    /// 새로고침 콜백
    var onRefresh: (() -> Void)?

    // MARK: - Computed Properties

    /// unread 배지 표시 여부 (unreadCount > 0)
    var isUnreadBadgeVisible: Bool {
        return unreadCount > 0
    }

    /// 새로고침 버튼 활성화 여부 (!isRefreshing)
    var isRefreshButtonEnabled: Bool {
        return !isRefreshing
    }

    /// unread 배지 텍스트.
    /// 99 이하: 실제 숫자, 100 이상: "99+"
    var unreadBadgeText: String {
        if unreadCount > 99 {
            return "99+"
        }
        return "\(unreadCount)"
    }

    // MARK: - Init

    init(
        pluginId: String,
        title: String,
        icon: String,
        unreadCount: Int
    ) {
        self.pluginId = pluginId
        self.title = title
        self.icon = icon
        self.unreadCount = unreadCount
    }

    // MARK: - Refresh

    /// 새로고침 상태를 시작합니다.
    func startRefreshing() {
        isRefreshing = true
    }

    /// 새로고침 상태를 종료합니다.
    func stopRefreshing() {
        isRefreshing = false
    }

    /// 새로고침 버튼 탭 처리.
    /// 새로고침 중이면 콜백을 호출하지 않습니다.
    func refreshTapped() {
        guard !isRefreshing else { return }
        onRefresh?()
    }

    // MARK: - Update

    /// 읽지 않은 항목 수를 업데이트합니다.
    func updateUnreadCount(_ count: Int) {
        unreadCount = count
    }
}
