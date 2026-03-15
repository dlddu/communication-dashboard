import XCTest
@testable import CommBoard

// MARK: - WidgetHeaderTests
//
// WidgetHeader의 표시 로직을 검증합니다.
// WidgetHeader는 위젯 카드 상단에 위치하며 아이콘, 제목, unread 배지,
// 새로고침 버튼으로 구성됩니다.
//
// 검증 대상:
//   - WidgetHeaderViewModel 초기화
//   - 아이콘 이름 접근
//   - 제목 텍스트 접근
//   - unread 배지 표시 여부 및 카운트 포맷
//   - 새로고침 버튼 상태 (로딩 중 비활성화)
//   - 새로고침 액션 호출 추적

final class WidgetHeaderTests: XCTestCase {

    // MARK: - Properties

    var sut: WidgetHeaderViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test Widget",
            icon: "bell.fill",
            unreadCount: 0
        )
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_PluginId_IsSet() {
        // Assert
        XCTAssertEqual(sut.pluginId, "test-plugin", "pluginId가 올바르게 설정되어야 합니다")
    }

    func testInitialization_Title_IsSet() {
        // Assert
        XCTAssertEqual(sut.title, "Test Widget", "제목이 올바르게 설정되어야 합니다")
    }

    func testInitialization_Icon_IsSet() {
        // Assert
        XCTAssertEqual(sut.icon, "bell.fill", "SF Symbols 아이콘 이름이 올바르게 설정되어야 합니다")
    }

    func testInitialization_UnreadCount_IsZero() {
        // Assert
        XCTAssertEqual(sut.unreadCount, 0, "초기 unread count는 0이어야 합니다")
    }

    func testInitialization_IsRefreshing_IsFalse() {
        // Assert
        XCTAssertFalse(sut.isRefreshing, "초기 새로고침 상태는 false여야 합니다")
    }

    // MARK: - Unread Badge Tests

    func testUnreadBadge_WhenZero_IsNotVisible() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 0
        )

        // Assert
        XCTAssertFalse(
            sut.isUnreadBadgeVisible,
            "unread count가 0일 때 배지가 표시되지 않아야 합니다"
        )
    }

    func testUnreadBadge_WhenPositive_IsVisible() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 3
        )

        // Assert
        XCTAssertTrue(
            sut.isUnreadBadgeVisible,
            "unread count가 양수일 때 배지가 표시되어야 합니다"
        )
    }

    func testUnreadBadgeText_WhenCountIsSmall_ShowsActualCount() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 5
        )

        // Act
        let badgeText = sut.unreadBadgeText

        // Assert
        XCTAssertEqual(badgeText, "5", "unread count 5는 '5'로 표시되어야 합니다")
    }

    func testUnreadBadgeText_WhenCountIsNinetyNine_ShowsActualCount() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 99
        )

        // Act
        let badgeText = sut.unreadBadgeText

        // Assert
        XCTAssertEqual(badgeText, "99", "unread count 99는 '99'로 표시되어야 합니다")
    }

    func testUnreadBadgeText_WhenCountExceedsNinetyNine_ShowsPlus() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 100
        )

        // Act
        let badgeText = sut.unreadBadgeText

        // Assert
        XCTAssertEqual(
            badgeText,
            "99+",
            "unread count가 100 이상이면 '99+'로 표시되어야 합니다"
        )
    }

    func testUnreadBadgeText_WhenCountIsLarge_ShowsPlus() {
        // Arrange
        sut = WidgetHeaderViewModel(
            pluginId: "test-plugin",
            title: "Test",
            icon: "star",
            unreadCount: 1000
        )

        // Act
        let badgeText = sut.unreadBadgeText

        // Assert
        XCTAssertEqual(
            badgeText,
            "99+",
            "unread count가 1000이면 '99+'로 표시되어야 합니다"
        )
    }

    // MARK: - Refresh Button Tests

    func testRefreshButton_WhenNotRefreshing_IsEnabled() {
        // Arrange
        sut.isRefreshing = false

        // Assert
        XCTAssertTrue(
            sut.isRefreshButtonEnabled,
            "새로고침 중이 아닐 때 버튼이 활성화되어야 합니다"
        )
    }

    func testRefreshButton_WhenRefreshing_IsDisabled() {
        // Arrange
        sut.isRefreshing = true

        // Assert
        XCTAssertFalse(
            sut.isRefreshButtonEnabled,
            "새로고침 중일 때 버튼이 비활성화되어야 합니다"
        )
    }

    func testStartRefreshing_SetsIsRefreshingToTrue() {
        // Arrange
        XCTAssertFalse(sut.isRefreshing)

        // Act
        sut.startRefreshing()

        // Assert
        XCTAssertTrue(sut.isRefreshing, "startRefreshing() 호출 후 isRefreshing이 true여야 합니다")
    }

    func testStopRefreshing_SetsIsRefreshingToFalse() {
        // Arrange
        sut.startRefreshing()
        XCTAssertTrue(sut.isRefreshing)

        // Act
        sut.stopRefreshing()

        // Assert
        XCTAssertFalse(sut.isRefreshing, "stopRefreshing() 호출 후 isRefreshing이 false여야 합니다")
    }

    // MARK: - Refresh Action Tests

    func testOnRefreshTapped_CallsRefreshCallback() async throws {
        // Arrange
        var refreshCalled = false
        sut.onRefresh = {
            refreshCalled = true
        }

        // Act
        sut.refreshTapped()

        // Assert
        XCTAssertTrue(refreshCalled, "새로고침 버튼 탭 시 onRefresh 콜백이 호출되어야 합니다")
    }

    func testOnRefreshTapped_WhenRefreshing_DoesNotCallCallback() {
        // Arrange
        var refreshCallCount = 0
        sut.onRefresh = { refreshCallCount += 1 }
        sut.startRefreshing()

        // Act
        sut.refreshTapped()

        // Assert
        XCTAssertEqual(
            refreshCallCount,
            0,
            "이미 새로고침 중일 때 버튼 탭은 콜백을 호출하지 않아야 합니다"
        )
    }

    // MARK: - Title Validation Tests

    func testTitle_IsNonEmpty_ForValidPlugin() {
        // Assert
        XCTAssertFalse(sut.title.isEmpty, "위젯 제목은 비어있지 않아야 합니다")
    }

    func testIcon_IsNonEmpty_ForValidPlugin() {
        // Assert
        XCTAssertFalse(sut.icon.isEmpty, "위젯 아이콘 이름은 비어있지 않아야 합니다")
    }

    // MARK: - Update Tests

    func testUpdateUnreadCount_UpdatesValue() {
        // Arrange
        XCTAssertEqual(sut.unreadCount, 0)

        // Act
        sut.updateUnreadCount(7)

        // Assert
        XCTAssertEqual(sut.unreadCount, 7, "updateUnreadCount() 호출 후 unreadCount가 업데이트되어야 합니다")
    }

    func testUpdateUnreadCount_ToZero_HidesBadge() {
        // Arrange
        sut.updateUnreadCount(5)
        XCTAssertTrue(sut.isUnreadBadgeVisible)

        // Act
        sut.updateUnreadCount(0)

        // Assert
        XCTAssertFalse(
            sut.isUnreadBadgeVisible,
            "unreadCount를 0으로 업데이트하면 배지가 숨겨져야 합니다"
        )
    }
}
