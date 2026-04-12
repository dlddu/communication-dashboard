import XCTest

// MARK: - EditModeTests
//
// Dashboard 위젯 편집 모드(Edit Mode)의 UI 동작을 검증합니다.
// 편집 모드 진입, 위젯 크기 변경, 위젯 삭제, 편집 완료 후 복귀 등을 확인합니다.
//
// 관련 이슈: DLD-755
// 구현 이슈: DLD-756 (edit_mode_button, widget_remove_button, widget_size_selector 등 할당 예정)

final class EditModeTests: UITestBase {

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await super.tearDown()
    }

    // MARK: - Edit Mode Entry Tests

    /// Dashboard에서 편집 버튼을 탭하면 Edit Mode로 진입해야 합니다.
    func testEditMode_TapEditButton_EntersEditMode() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: 위젯 그리드가 표시될 때까지 대기
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)
        XCTAssertTrue(gridExists, "dashboard_widget_grid 컨테이너가 표시되어야 합니다")

        // Act: 편집 버튼 탭
        let editButton = app.buttons["edit_mode_button"]
        let editButtonExists = editButton.waitForExistence(timeout: 10.0)
        XCTAssertTrue(editButtonExists, "edit_mode_button이 표시되어야 합니다")
        editButton.tap()

        // Assert: 완료 버튼이 표시되면 편집 모드 진입 확인
        let doneButton = app.buttons["edit_mode_button"]
        let doneButtonExists = doneButton.waitForExistence(timeout: 5.0)
        XCTAssertTrue(
            doneButtonExists,
            "편집 버튼 탭 후 edit_mode_button이 '완료' 레이블로 변경되어야 합니다"
        )
        XCTAssertEqual(
            doneButton.label,
            "완료",
            "편집 모드 진입 후 버튼 레이블이 '완료'여야 합니다"
        )
    }

    // MARK: - Widget Size Change Tests

    /// 편집 모드에서 위젯 크기를 small에서 medium으로 변경하면 그리드에 반영되어야 합니다.
    func testEditMode_ChangeWidgetSize_ReflectsInGrid() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: 위젯 그리드 대기
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)
        XCTAssertTrue(gridExists, "dashboard_widget_grid 컨테이너가 표시되어야 합니다")

        // Assert: 변경 전 small 셀 존재 확인 및 프레임 기록
        let smallCell = app.otherElements["widget_cell_small"]
        let smallExists = smallCell.waitForExistence(timeout: 10.0)
        XCTAssertTrue(smallExists, "크기 변경 전 widget_cell_small 셀이 표시되어야 합니다")
        let smallFrameBefore = smallCell.frame

        // Act: 편집 모드 진입
        let editButton = app.buttons["edit_mode_button"]
        editButton.waitForExistence(timeout: 10.0)
        editButton.tap()

        // Act: small 셀의 크기 선택기를 열고 medium 선택
        let sizeSelector = app.otherElements["widget_size_selector"]
        let selectorExists = sizeSelector.waitForExistence(timeout: 5.0)
        XCTAssertTrue(selectorExists, "편집 모드에서 widget_size_selector가 표시되어야 합니다")
        sizeSelector.tap()

        let mediumOption = app.buttons["size_option_medium"]
        let mediumOptionExists = mediumOption.waitForExistence(timeout: 5.0)
        XCTAssertTrue(mediumOptionExists, "size_option_medium 옵션이 표시되어야 합니다")
        mediumOption.tap()

        // Assert: 크기 변경 후 medium 셀이 그리드에 표시되어야 합니다
        let mediumCell = app.otherElements["widget_cell_medium"]
        let mediumExists = mediumCell.waitForExistence(timeout: 5.0)
        XCTAssertTrue(mediumExists, "크기 변경 후 widget_cell_medium 셀이 표시되어야 합니다")

        // Assert: medium 셀 면적이 변경 전 small 셀 면적보다 커야 합니다
        let mediumFrame = mediumCell.frame
        XCTAssertGreaterThan(
            mediumFrame.width * mediumFrame.height,
            smallFrameBefore.width * smallFrameBefore.height,
            "medium으로 변경된 위젯 셀 면적이 변경 전 small 셀 면적보다 커야 합니다"
        )
    }

    // MARK: - Widget Removal Tests

    /// 편집 모드에서 위젯 삭제(✕) 버튼을 탭하면 해당 위젯이 그리드에서 제거되어야 합니다.
    func testEditMode_TapRemoveButton_RemovesWidgetFromGrid() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: 위젯 그리드 대기
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)
        XCTAssertTrue(gridExists, "dashboard_widget_grid 컨테이너가 표시되어야 합니다")

        // Assert: 삭제 전 위젯 셀 수 확인
        let cellsBefore = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'widget_cell'")
        )
        let countBefore = cellsBefore.count
        XCTAssertGreaterThan(countBefore, 0, "삭제 전 그리드에 위젯 셀이 최소 1개 이상 있어야 합니다")

        // Act: 편집 모드 진입
        let editButton = app.buttons["edit_mode_button"]
        editButton.waitForExistence(timeout: 10.0)
        editButton.tap()

        // Act: 첫 번째 위젯의 삭제(✕) 버튼 탭
        let removeButton = app.buttons["widget_remove_button"]
        let removeButtonExists = removeButton.waitForExistence(timeout: 5.0)
        XCTAssertTrue(removeButtonExists, "편집 모드에서 widget_remove_button이 표시되어야 합니다")
        removeButton.tap()

        // Assert: 삭제 후 위젯 셀 수가 1 감소해야 합니다
        let cellsAfter = app.otherElements.matching(
            NSPredicate(format: "identifier BEGINSWITH 'widget_cell'")
        )
        let countAfter = cellsAfter.count
        XCTAssertEqual(
            countAfter,
            countBefore - 1,
            "위젯 삭제 후 그리드의 위젯 셀 수가 1 감소해야 합니다. 삭제 전: \(countBefore), 삭제 후: \(countAfter)"
        )
    }

    // MARK: - Edit Mode Exit Tests

    /// 편집 모드에서 "완료" 버튼을 탭하면 Dashboard로 복귀하고 변경사항이 유지되어야 합니다.
    func testEditMode_TapDoneButton_ReturnsToDashboardWithChanges() throws {
        // Arrange & Act
        launchAppInMockMode()

        // Assert: 위젯 그리드 대기
        let widgetGrid = app.otherElements["dashboard_widget_grid"]
        let gridExists = widgetGrid.waitForExistence(timeout: 10.0)
        XCTAssertTrue(gridExists, "dashboard_widget_grid 컨테이너가 표시되어야 합니다")

        // Act: 편집 모드 진입 후 크기 변경
        let editButton = app.buttons["edit_mode_button"]
        editButton.waitForExistence(timeout: 10.0)
        editButton.tap()

        let sizeSelector = app.otherElements["widget_size_selector"]
        sizeSelector.waitForExistence(timeout: 5.0)
        sizeSelector.tap()

        let mediumOption = app.buttons["size_option_medium"]
        mediumOption.waitForExistence(timeout: 5.0)
        mediumOption.tap()

        // Act: 완료 버튼 탭하여 편집 모드 종료
        let doneButton = app.buttons["edit_mode_button"]
        let doneButtonExists = doneButton.waitForExistence(timeout: 5.0)
        XCTAssertTrue(doneButtonExists, "편집 모드 중 edit_mode_button('완료')이 표시되어야 합니다")
        XCTAssertEqual(doneButton.label, "완료", "편집 모드 중 버튼 레이블이 '완료'여야 합니다")
        doneButton.tap()

        // Assert: 편집 모드 종료 후 버튼 레이블이 '편집'으로 복귀해야 합니다
        let editButtonAfter = app.buttons["edit_mode_button"]
        let editButtonAfterExists = editButtonAfter.waitForExistence(timeout: 5.0)
        XCTAssertTrue(editButtonAfterExists, "완료 버튼 탭 후 edit_mode_button이 다시 표시되어야 합니다")
        XCTAssertEqual(
            editButtonAfter.label,
            "편집",
            "편집 모드 종료 후 버튼 레이블이 '편집'으로 복귀해야 합니다"
        )

        // Assert: 위젯 그리드가 여전히 표시되어야 합니다 (Dashboard 복귀 확인)
        let widgetGridAfter = app.otherElements["dashboard_widget_grid"]
        let gridAfterExists = widgetGridAfter.waitForExistence(timeout: 5.0)
        XCTAssertTrue(gridAfterExists, "편집 모드 종료 후 dashboard_widget_grid가 계속 표시되어야 합니다")

        // Assert: 편집 중 변경한 medium 셀이 유지되어야 합니다
        let mediumCell = app.otherElements["widget_cell_medium"]
        let mediumExists = mediumCell.waitForExistence(timeout: 5.0)
        XCTAssertTrue(
            mediumExists,
            "편집 모드 종료 후 크기 변경된 widget_cell_medium이 그리드에 유지되어야 합니다"
        )
    }
}
