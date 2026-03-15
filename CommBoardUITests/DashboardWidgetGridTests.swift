import XCTest

// MARK: - DashboardWidgetGridTests
//
// Dashboard 위젯 그리드 화면의 UI 동작을 검증합니다.
// 위젯 그리드 컨테이너 표시, 위젯 셀 목록, 크기별 셀 프레임,
// 상태바 마지막 동기화 시간 표시 등을 확인합니다.
//
// 관련 이슈: DLD-753

final class DashboardWidgetGridTests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Dashboard Widget Grid Container Tests

    /// mock 모드로 앱 실행 시 Dashboard 위젯 그리드 컨테이너가 표시되어야 합니다.
    func testDashboardWidgetGrid_ShowsGridContainer() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: dashboard_widget_grid 컨테이너가 화면에 표시되는지 확인
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            gridExists,
            "mock 모드로 실행 시 dashboard_widget_grid 컨테이너가 표시되어야 합니다"
        )
    }

    // MARK: - Widget Cell List Tests

    /// 위젯 그리드 안에 위젯 셀들이 하나 이상 표시되어야 합니다.
    func testDashboardWidgetGrid_ShowsWidgetCells() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: dashboard_widget_grid 컨테이너 대기
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)
        XCTAssertTrue(gridExists, "dashboard_widget_grid 컨테이너가 표시되어야 합니다")

        // Assert: widget_cell_0 또는 widget_cell 접두사를 가진 셀 중 첫 번째가 존재하는지 확인
        let firstCell = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'widget_cell'")
        ).firstMatch
        let cellExists = firstCell.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            cellExists,
            "위젯 그리드 안에 widget_cell 접두사를 가진 위젯 셀이 최소 1개 이상 표시되어야 합니다"
        )
    }

    // MARK: - Widget Cell Size Tests

    /// 위젯 크기("small", "medium", "large")에 따라 셀 프레임 크기가 달라야 합니다.
    func testDashboardWidgetGrid_WidgetCellSizes_DifferByLayout() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: 각 사이즈별 대표 셀 대기
        let smallCell = app.otherElements["widget_cell_small"]
        let mediumCell = app.otherElements["widget_cell_medium"]
        let largeCell = app.otherElements["widget_cell_large"]

        let smallExists = smallCell.waitForExistence(timeout: 10.0)
        let mediumExists = mediumCell.waitForExistence(timeout: 10.0)
        let largeExists = largeCell.waitForExistence(timeout: 10.0)

        XCTAssertTrue(smallExists, "widget_cell_small 셀이 표시되어야 합니다")
        XCTAssertTrue(mediumExists, "widget_cell_medium 셀이 표시되어야 합니다")
        XCTAssertTrue(largeExists, "widget_cell_large 셀이 표시되어야 합니다")

        // Assert: 셀 프레임 크기가 size 순서에 따라 증가해야 합니다
        let smallFrame = smallCell.frame
        let mediumFrame = mediumCell.frame
        let largeFrame = largeCell.frame

        XCTAssertLessThan(
            smallFrame.width * smallFrame.height,
            mediumFrame.width * mediumFrame.height,
            "small 위젯 셀 면적이 medium보다 작아야 합니다"
        )
        XCTAssertLessThan(
            mediumFrame.width * mediumFrame.height,
            largeFrame.width * largeFrame.height,
            "medium 위젯 셀 면적이 large보다 작아야 합니다"
        )
    }

    // MARK: - Status Bar Last Sync Tests

    /// 상태바 영역에 마지막 동기화 시간 텍스트가 표시되어야 합니다.
    func testDashboardStatusBar_ShowsLastSyncTime() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: status_bar_last_sync 요소가 표시되는지 확인
        let lastSyncLabel = app.staticTexts["status_bar_last_sync"]
        let labelExists = lastSyncLabel.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            labelExists,
            "상태바에 status_bar_last_sync 식별자를 가진 마지막 동기화 시간 텍스트가 표시되어야 합니다"
        )

        // Assert: 텍스트가 비어있지 않아야 합니다
        let labelValue = lastSyncLabel.label
        XCTAssertFalse(
            labelValue.isEmpty,
            "마지막 동기화 시간 텍스트가 비어있지 않아야 합니다"
        )

        // Assert: 날짜/시간 형식 패턴을 포함해야 합니다 (예: ":" 또는 "/" 또는 "-" 포함)
        let containsTimePattern = labelValue.contains(":")
            || labelValue.contains("/")
            || labelValue.contains("-")

        XCTAssertTrue(
            containsTimePattern,
            "마지막 동기화 시간 텍스트가 날짜/시간 형식 패턴(':', '/', '-')을 포함해야 합니다. 실제 값: \(labelValue)"
        )
    }
}
