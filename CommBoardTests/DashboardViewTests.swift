import XCTest
@testable import CommBoard

// MARK: - DashboardViewTests
//
// DashboardView의 ViewModel 로직을 검증합니다.
// DashboardView는 TitleBar + WidgetGridView + StatusBar를 조합한 메인 화면입니다.
//
// 검증 대상:
//   - DashboardViewModel 초기화 및 상태 관리
//   - 연결 상태(ConnectionStatus) 전환 로직
//   - 편집 모드 토글
//   - 위젯 레이아웃 로드 및 에러 처리
//   - 로딩/비어있음/에러 상태 전환

final class DashboardViewTests: XCTestCase {

    // MARK: - Properties

    var sut: DashboardViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = DashboardViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_DefaultState_IsLoading() {
        // Arrange & Act - setUp에서 이미 초기화됨

        // Assert
        XCTAssertEqual(
            sut.loadingState,
            .loading,
            "초기 상태는 loading이어야 합니다"
        )
    }

    func testInitialization_DefaultWidgets_IsEmpty() {
        // Assert
        XCTAssertTrue(
            sut.widgets.isEmpty,
            "초기 위젯 목록은 비어있어야 합니다"
        )
    }

    func testInitialization_DefaultConnectionStatus_IsDisconnected() {
        // Assert
        XCTAssertEqual(
            sut.connectionStatus,
            .disconnected,
            "초기 연결 상태는 disconnected여야 합니다"
        )
    }

    func testInitialization_DefaultEditMode_IsFalse() {
        // Assert
        XCTAssertFalse(
            sut.isEditMode,
            "초기 편집 모드는 비활성 상태여야 합니다"
        )
    }

    // MARK: - Edit Mode Tests

    func testToggleEditMode_FromFalse_BecomesTrue() {
        // Arrange
        XCTAssertFalse(sut.isEditMode)

        // Act
        sut.toggleEditMode()

        // Assert
        XCTAssertTrue(sut.isEditMode, "편집 모드 토글 후 true가 되어야 합니다")
    }

    func testToggleEditMode_FromTrue_BecomesFalse() {
        // Arrange
        sut.toggleEditMode()
        XCTAssertTrue(sut.isEditMode)

        // Act
        sut.toggleEditMode()

        // Assert
        XCTAssertFalse(sut.isEditMode, "편집 모드 재토글 후 false가 되어야 합니다")
    }

    func testToggleEditMode_MultipleTimes_CorrectlyAlternates() {
        // Act & Assert
        for i in 1...4 {
            sut.toggleEditMode()
            let expected = (i % 2 == 1)
            XCTAssertEqual(
                sut.isEditMode,
                expected,
                "\(i)번 토글 후 편집 모드가 \(expected)여야 합니다"
            )
        }
    }

    // MARK: - Connection Status Tests

    func testUpdateConnectionStatus_ToConnected_Succeeds() {
        // Act
        sut.updateConnectionStatus(.connected)

        // Assert
        XCTAssertEqual(
            sut.connectionStatus,
            .connected,
            "연결 상태가 connected로 업데이트되어야 합니다"
        )
    }

    func testUpdateConnectionStatus_ToConnecting_Succeeds() {
        // Act
        sut.updateConnectionStatus(.connecting)

        // Assert
        XCTAssertEqual(
            sut.connectionStatus,
            .connecting,
            "연결 상태가 connecting으로 업데이트되어야 합니다"
        )
    }

    func testUpdateConnectionStatus_ToError_Succeeds() {
        // Act
        sut.updateConnectionStatus(.error)

        // Assert
        XCTAssertEqual(
            sut.connectionStatus,
            .error,
            "연결 상태가 error로 업데이트되어야 합니다"
        )
    }

    func testUpdateConnectionStatus_ToDisconnected_Succeeds() {
        // Arrange
        sut.updateConnectionStatus(.connected)

        // Act
        sut.updateConnectionStatus(.disconnected)

        // Assert
        XCTAssertEqual(
            sut.connectionStatus,
            .disconnected,
            "연결 상태가 disconnected로 업데이트되어야 합니다"
        )
    }

    // MARK: - Loading State Tests

    func testLoadingState_WhenLoadWidgetsFails_IsError() async {
        // Arrange
        let errorMessage = "연결 실패"

        // Act
        await sut.setLoadingState(.error(message: errorMessage))

        // Assert
        if case .error(let message) = sut.loadingState {
            XCTAssertEqual(message, errorMessage, "에러 메시지가 올바르게 설정되어야 합니다")
        } else {
            XCTFail("loadingState가 .error여야 합니다")
        }
    }

    func testLoadingState_WhenWidgetsLoaded_IsLoaded() async {
        // Arrange
        let layouts = [
            WidgetLayout(pluginId: "plugin-a", positionX: 0, positionY: 0, size: "small", order: 0)
        ]

        // Act
        await sut.setLoadingState(.loaded)
        sut.widgets = layouts

        // Assert
        XCTAssertEqual(sut.loadingState, .loaded, "위젯 로드 완료 후 상태는 loaded여야 합니다")
        XCTAssertEqual(sut.widgets.count, 1, "위젯 목록에 1개가 포함되어야 합니다")
    }

    func testLoadingState_WhenNoWidgets_IsEmpty() async {
        // Act
        await sut.setLoadingState(.empty)

        // Assert
        XCTAssertEqual(sut.loadingState, .empty, "위젯이 없을 때 상태는 empty여야 합니다")
    }

    // MARK: - Loading State Transitions

    func testLoadingState_TransitionFromLoadingToLoaded() async {
        // Arrange
        XCTAssertEqual(sut.loadingState, .loading)

        // Act
        await sut.setLoadingState(.loaded)

        // Assert
        XCTAssertEqual(sut.loadingState, .loaded, "loading에서 loaded로 전환되어야 합니다")
    }

    func testLoadingState_TransitionFromLoadingToEmpty() async {
        // Arrange
        XCTAssertEqual(sut.loadingState, .loading)

        // Act
        await sut.setLoadingState(.empty)

        // Assert
        XCTAssertEqual(sut.loadingState, .empty, "loading에서 empty로 전환되어야 합니다")
    }

    func testLoadingState_TransitionFromLoadingToError() async {
        // Arrange
        XCTAssertEqual(sut.loadingState, .loading)

        // Act
        await sut.setLoadingState(.error(message: "테스트 에러"))

        // Assert
        if case .error = sut.loadingState {
            // OK
        } else {
            XCTFail("loading에서 error로 전환되어야 합니다")
        }
    }

    // MARK: - Retry Tests

    func testRetry_ResetsState_ToLoading() async {
        // Arrange
        await sut.setLoadingState(.error(message: "네트워크 오류"))

        // Act
        await sut.retry()

        // Assert
        XCTAssertEqual(
            sut.loadingState,
            .loading,
            "재시도 시 상태가 loading으로 초기화되어야 합니다"
        )
    }

    func testRetry_FromEmptyState_ResetsToLoading() async {
        // Arrange
        await sut.setLoadingState(.empty)

        // Act
        await sut.retry()

        // Assert
        XCTAssertEqual(
            sut.loadingState,
            .loading,
            "empty 상태에서 재시도 시 loading으로 돌아가야 합니다"
        )
    }

    // MARK: - Title Bar Tests

    func testTitleBar_AppName_IsCommBoard() {
        // Assert
        XCTAssertEqual(sut.appName, "CommBoard", "앱 이름이 'CommBoard'여야 합니다")
    }

    // MARK: - Connection Status Equality Tests

    func testConnectionStatus_AllCases_AreEquatable() {
        // Assert
        XCTAssertEqual(ConnectionStatus.connected, ConnectionStatus.connected)
        XCTAssertEqual(ConnectionStatus.connecting, ConnectionStatus.connecting)
        XCTAssertEqual(ConnectionStatus.disconnected, ConnectionStatus.disconnected)
        XCTAssertEqual(ConnectionStatus.error, ConnectionStatus.error)
        XCTAssertNotEqual(ConnectionStatus.connected, ConnectionStatus.disconnected)
    }

    // MARK: - Loading State Equality Tests

    func testDashboardLoadingState_LoadedEqualsLoaded() {
        // Assert
        XCTAssertEqual(DashboardLoadingState.loaded, DashboardLoadingState.loaded)
    }

    func testDashboardLoadingState_ErrorWithSameMessage_AreEqual() {
        // Assert
        XCTAssertEqual(
            DashboardLoadingState.error(message: "test"),
            DashboardLoadingState.error(message: "test")
        )
    }

    func testDashboardLoadingState_ErrorWithDifferentMessage_AreNotEqual() {
        // Assert
        XCTAssertNotEqual(
            DashboardLoadingState.error(message: "a"),
            DashboardLoadingState.error(message: "b")
        )
    }
}
