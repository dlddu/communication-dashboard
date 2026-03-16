import XCTest
@testable import CommBoard

// MARK: - EditModeViewModelTests
//
// EditMode 기능의 ViewModel 로직을 검증합니다.
// 편집 모드 진입/종료, 위젯 크기 변경, 위젯 삭제, 위젯 재정렬,
// AddWidgetPopover, 저장/실패 상태 등을 확인합니다.
//
// 관련 이슈: DLD-755 / DLD-756
//
// 검증 대상:
//   - EditModeViewModel 초기 상태
//   - 위젯 크기 변경 (size 필드 + DB 반영)
//   - 위젯 삭제 (DB row 제거)
//   - 위젯 순서 재배치 (reorderWidgets)
//   - AddWidgetPopover 미배치 플러그인 목록
//   - 완료 버튼 → SQLite 저장 + 편집 모드 종료
//   - 저장 실패 시 Toast 상태
//   - 드래그 중 opacity 상태
//   - DatabaseManager 확장: updateWidgetSize / updateWidgetOrder

// MARK: - EditModeViewModel (Expected API Contract)
//
// code-writer가 구현해야 할 EditModeViewModel의 예상 인터페이스:
//
// class EditModeViewModel: ObservableObject {
//     @Published var editingWidgets: [WidgetLayout]       // 편집 중인 위젯 목록
//     @Published var isDragging: Bool                     // 드래그 중 여부
//     @Published var draggingWidgetId: String?            // 드래그 중인 위젯 stableId
//     @Published var showSaveFailureToast: Bool           // 저장 실패 Toast 표시 여부
//     @Published var unplacedPluginIds: [String]          // 미배치 플러그인 ID 목록
//
//     init(widgets: [WidgetLayout], allPluginIds: [String], dbManager: DatabaseManager)
//
//     func changeWidgetSize(widgetId: String, to newSize: String) throws
//     func removeWidget(widgetId: String) throws
//     func reorderWidgets(fromIndex: Int, toIndex: Int) throws
//     func addWidget(pluginId: String) throws
//     func saveAndExit() async throws       // 성공 시 → DashboardViewModel.isEditMode = false
//     func setDragging(widgetId: String?)
//     func draggingOpacity(for widgetId: String) -> Double
// }
//
// DatabaseManager 확장:
//   func updateWidgetSize(id: Int64, size: String) throws
//   func updateWidgetOrder(id: Int64, order: Int) throws

final class EditModeViewModelTests: XCTestCase {

    // MARK: - Properties

    var sut: EditModeViewModel!
    var dbManager: DatabaseManager!

    // MARK: - Fixtures

    /// 테스트용 기본 위젯 레이아웃 목록
    private func makeWidgets() -> [WidgetLayout] {
        return [
            WidgetLayout(id: 1, pluginId: "slack", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(id: 2, pluginId: "github", positionX: 1, positionY: 0, size: "medium", order: 1),
            WidgetLayout(id: 3, pluginId: "jira", positionX: 2, positionY: 0, size: "large", order: 2),
        ]
    }

    /// 테스트용 전체 플러그인 ID 목록 (배치된 것 + 미배치 것 포함)
    private func makeAllPluginIds() -> [String] {
        return ["slack", "github", "jira", "notion", "figma"]
    }

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        dbManager = try DatabaseManager(inMemory: true)
        let widgets = makeWidgets()
        // DB에 픽스처 삽입
        for var layout in widgets {
            _ = try dbManager.insertWidgetLayout(layout)
        }
        let dbWidgets = try dbManager.fetchWidgetLayouts()
        sut = EditModeViewModel(
            widgets: dbWidgets,
            allPluginIds: makeAllPluginIds(),
            dbManager: dbManager
        )
    }

    override func tearDown() async throws {
        sut = nil
        dbManager = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_EditingWidgets_MatchesInput() {
        // Arrange & Act - setUp에서 이미 초기화됨

        // Assert
        XCTAssertEqual(
            sut.editingWidgets.count,
            3,
            "초기 editingWidgets 수는 입력된 위젯 수와 같아야 합니다"
        )
    }

    func testInitialization_IsDragging_IsFalse() {
        // Assert
        XCTAssertFalse(
            sut.isDragging,
            "초기 isDragging은 false여야 합니다"
        )
    }

    func testInitialization_DraggingWidgetId_IsNil() {
        // Assert
        XCTAssertNil(
            sut.draggingWidgetId,
            "초기 draggingWidgetId는 nil이어야 합니다"
        )
    }

    func testInitialization_ShowSaveFailureToast_IsFalse() {
        // Assert
        XCTAssertFalse(
            sut.showSaveFailureToast,
            "초기 showSaveFailureToast는 false여야 합니다"
        )
    }

    func testInitialization_UnplacedPluginIds_ExcludesAlreadyPlacedPlugins() {
        // Arrange
        // makeAllPluginIds()에는 slack, github, jira, notion, figma
        // makeWidgets()에는 slack, github, jira가 이미 배치됨

        // Assert
        XCTAssertFalse(
            sut.unplacedPluginIds.contains("slack"),
            "이미 배치된 'slack'은 미배치 목록에 없어야 합니다"
        )
        XCTAssertFalse(
            sut.unplacedPluginIds.contains("github"),
            "이미 배치된 'github'은 미배치 목록에 없어야 합니다"
        )
        XCTAssertFalse(
            sut.unplacedPluginIds.contains("jira"),
            "이미 배치된 'jira'는 미배치 목록에 없어야 합니다"
        )
    }

    func testInitialization_UnplacedPluginIds_IncludesNotYetPlacedPlugins() {
        // Assert
        XCTAssertTrue(
            sut.unplacedPluginIds.contains("notion"),
            "미배치 'notion'은 미배치 목록에 있어야 합니다"
        )
        XCTAssertTrue(
            sut.unplacedPluginIds.contains("figma"),
            "미배치 'figma'는 미배치 목록에 있어야 합니다"
        )
    }

    func testInitialization_UnplacedPluginIds_CountIsCorrect() {
        // Arrange: allPluginIds 5개 - placed 3개 = unplaced 2개

        // Assert
        XCTAssertEqual(
            sut.unplacedPluginIds.count,
            2,
            "미배치 플러그인 수는 2이어야 합니다 (notion, figma)"
        )
    }

    // MARK: - Widget Size Change Tests

    func testChangeWidgetSize_ToMedium_UpdatesEditingWidgets() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!
        XCTAssertEqual(target.size, "small")

        // Act
        try sut.changeWidgetSize(widgetId: target.stableId, to: "medium")

        // Assert
        let updated = sut.editingWidgets.first { $0.pluginId == "slack" }!
        XCTAssertEqual(
            updated.size,
            "medium",
            "changeWidgetSize 후 editingWidgets에서 해당 위젯 크기가 'medium'이어야 합니다"
        )
    }

    func testChangeWidgetSize_ToWide_UpdatesEditingWidgets() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!

        // Act
        try sut.changeWidgetSize(widgetId: target.stableId, to: "wide")

        // Assert
        let updated = sut.editingWidgets.first { $0.pluginId == "slack" }!
        XCTAssertEqual(updated.size, "wide", "wide로 크기 변경이 반영되어야 합니다")
    }

    func testChangeWidgetSize_ToLarge_UpdatesEditingWidgets() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!

        // Act
        try sut.changeWidgetSize(widgetId: target.stableId, to: "large")

        // Assert
        let updated = sut.editingWidgets.first { $0.pluginId == "slack" }!
        XCTAssertEqual(updated.size, "large", "large로 크기 변경이 반영되어야 합니다")
    }

    func testChangeWidgetSize_ToSmall_UpdatesEditingWidgets() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "github" }!
        XCTAssertEqual(target.size, "medium")

        // Act
        try sut.changeWidgetSize(widgetId: target.stableId, to: "small")

        // Assert
        let updated = sut.editingWidgets.first { $0.pluginId == "github" }!
        XCTAssertEqual(updated.size, "small", "small로 크기 변경이 반영되어야 합니다")
    }

    func testChangeWidgetSize_UpdatesDatabase() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!
        guard let id = target.id else {
            XCTFail("위젯 ID가 있어야 합니다")
            return
        }

        // Act
        try sut.changeWidgetSize(widgetId: target.stableId, to: "medium")

        // Assert
        let dbWidget = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(
            dbWidget?.size,
            "medium",
            "changeWidgetSize 후 DB의 size 컬럼이 'medium'으로 업데이트되어야 합니다"
        )
    }

    func testChangeWidgetSize_WithInvalidId_ThrowsError() {
        // Arrange
        let invalidId = "nonexistent_widget_id"

        // Act & Assert
        XCTAssertThrowsError(
            try sut.changeWidgetSize(widgetId: invalidId, to: "medium"),
            "존재하지 않는 widgetId에 대해 오류가 발생해야 합니다"
        )
    }

    func testChangeWidgetSize_WithAllValidSizes_DoesNotThrow() throws {
        // Arrange
        let target = sut.editingWidgets.first!
        let validSizes = ["small", "medium", "wide", "large"]

        // Act & Assert
        for size in validSizes {
            XCTAssertNoThrow(
                try sut.changeWidgetSize(widgetId: target.stableId, to: size),
                "유효한 크기 '\(size)'로 변경 시 오류가 없어야 합니다"
            )
        }
    }

    // MARK: - Widget Removal Tests

    func testRemoveWidget_DecreasesEditingWidgetsCount() throws {
        // Arrange
        let countBefore = sut.editingWidgets.count
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!

        // Act
        try sut.removeWidget(widgetId: target.stableId)

        // Assert
        XCTAssertEqual(
            sut.editingWidgets.count,
            countBefore - 1,
            "위젯 삭제 후 editingWidgets 수가 1 감소해야 합니다"
        )
    }

    func testRemoveWidget_RemovesTargetFromEditingWidgets() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!

        // Act
        try sut.removeWidget(widgetId: target.stableId)

        // Assert
        let stillExists = sut.editingWidgets.contains { $0.pluginId == "slack" }
        XCTAssertFalse(
            stillExists,
            "삭제된 'slack' 위젯이 editingWidgets에 남아있지 않아야 합니다"
        )
    }

    func testRemoveWidget_RemovesRowFromDatabase() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!
        guard let id = target.id else {
            XCTFail("위젯 ID가 있어야 합니다")
            return
        }

        // Act
        try sut.removeWidget(widgetId: target.stableId)

        // Assert
        let dbWidget = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertNil(
            dbWidget,
            "위젯 삭제 후 DB에서 해당 row가 존재하지 않아야 합니다"
        )
    }

    func testRemoveWidget_MovesPluginToUnplacedList() throws {
        // Arrange
        let target = sut.editingWidgets.first { $0.pluginId == "slack" }!
        XCTAssertFalse(sut.unplacedPluginIds.contains("slack"))

        // Act
        try sut.removeWidget(widgetId: target.stableId)

        // Assert
        XCTAssertTrue(
            sut.unplacedPluginIds.contains("slack"),
            "위젯 삭제 후 해당 플러그인이 미배치 목록에 추가되어야 합니다"
        )
    }

    func testRemoveWidget_WithInvalidId_ThrowsError() {
        // Arrange
        let invalidId = "nonexistent_widget_id"

        // Act & Assert
        XCTAssertThrowsError(
            try sut.removeWidget(widgetId: invalidId),
            "존재하지 않는 widgetId 삭제 시 오류가 발생해야 합니다"
        )
    }

    func testRemoveWidget_AllWidgets_EditingWidgetsBecomesEmpty() throws {
        // Arrange
        let allIds = sut.editingWidgets.map { $0.stableId }

        // Act
        for id in allIds {
            try sut.removeWidget(widgetId: id)
        }

        // Assert
        XCTAssertTrue(
            sut.editingWidgets.isEmpty,
            "모든 위젯 삭제 후 editingWidgets가 비어야 합니다"
        )
    }

    // MARK: - Widget Reorder Tests

    func testReorderWidgets_SwapsOrderValues() throws {
        // Arrange
        let initialFirst = sut.editingWidgets[0].pluginId  // order=0
        let initialSecond = sut.editingWidgets[1].pluginId  // order=1

        // Act: index 0과 index 1을 교환
        try sut.reorderWidgets(fromIndex: 0, toIndex: 1)

        // Assert
        XCTAssertEqual(
            sut.editingWidgets[0].pluginId,
            initialSecond,
            "reorder 후 index 0 위젯은 이전 index 1의 위젯이어야 합니다"
        )
        XCTAssertEqual(
            sut.editingWidgets[1].pluginId,
            initialFirst,
            "reorder 후 index 1 위젯은 이전 index 0의 위젯이어야 합니다"
        )
    }

    func testReorderWidgets_UpdatesOrderValues() throws {
        // Arrange: initial order: slack=0, github=1, jira=2

        // Act: slack을 마지막으로 이동 (index 0 → index 2)
        try sut.reorderWidgets(fromIndex: 0, toIndex: 2)

        // Assert: 재정렬 후 order 값이 인덱스에 맞게 재할당되어야 합니다
        for (index, widget) in sut.editingWidgets.enumerated() {
            XCTAssertEqual(
                widget.order,
                index,
                "reorder 후 위젯의 order 값이 인덱스와 일치해야 합니다. index=\(index), order=\(widget.order)"
            )
        }
    }

    func testReorderWidgets_UpdatesDatabase() throws {
        // Arrange
        let slackWidget = sut.editingWidgets.first { $0.pluginId == "slack" }!
        guard let slackId = slackWidget.id else {
            XCTFail("위젯 ID가 있어야 합니다")
            return
        }

        // Act: slack(index 0)을 index 2로 이동
        try sut.reorderWidgets(fromIndex: 0, toIndex: 2)

        // Assert
        let dbSlack = try dbManager.fetchWidgetLayout(id: slackId)
        XCTAssertEqual(
            dbSlack?.order,
            2,
            "reorder 후 DB의 order 컬럼이 새 순서(2)로 업데이트되어야 합니다"
        )
    }

    func testReorderWidgets_WithSameIndex_DoesNotChangeOrder() throws {
        // Arrange
        let ordersBefore = sut.editingWidgets.map { $0.order }

        // Act: 같은 인덱스로 reorder (변화 없음)
        try sut.reorderWidgets(fromIndex: 1, toIndex: 1)

        // Assert
        let ordersAfter = sut.editingWidgets.map { $0.order }
        XCTAssertEqual(
            ordersBefore,
            ordersAfter,
            "같은 인덱스로 reorder 시 순서가 변경되지 않아야 합니다"
        )
    }

    func testReorderWidgets_WithOutOfBoundsIndex_ThrowsError() {
        // Arrange
        let outOfBoundsIndex = sut.editingWidgets.count + 10

        // Act & Assert
        XCTAssertThrowsError(
            try sut.reorderWidgets(fromIndex: 0, toIndex: outOfBoundsIndex),
            "범위를 벗어난 인덱스로 reorder 시 오류가 발생해야 합니다"
        )
    }

    func testReorderWidgets_MaintainsWidgetCount() throws {
        // Arrange
        let countBefore = sut.editingWidgets.count

        // Act
        try sut.reorderWidgets(fromIndex: 0, toIndex: 2)

        // Assert
        XCTAssertEqual(
            sut.editingWidgets.count,
            countBefore,
            "reorder 후 위젯 수가 변경되지 않아야 합니다"
        )
    }

    // MARK: - Add Widget Tests

    func testAddWidget_IncreasesEditingWidgetsCount() throws {
        // Arrange
        let countBefore = sut.editingWidgets.count

        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        XCTAssertEqual(
            sut.editingWidgets.count,
            countBefore + 1,
            "위젯 추가 후 editingWidgets 수가 1 증가해야 합니다"
        )
    }

    func testAddWidget_AppendsNewWidgetToEditingWidgets() throws {
        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        let added = sut.editingWidgets.first { $0.pluginId == "notion" }
        XCTAssertNotNil(
            added,
            "추가된 위젯이 editingWidgets에 포함되어야 합니다"
        )
    }

    func testAddWidget_NewWidget_HasDefaultSmallSize() throws {
        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        let added = sut.editingWidgets.first { $0.pluginId == "notion" }!
        XCTAssertEqual(
            added.size,
            "small",
            "새로 추가된 위젯의 기본 크기는 'small'이어야 합니다"
        )
    }

    func testAddWidget_RemovesFromUnplacedList() throws {
        // Arrange
        XCTAssertTrue(sut.unplacedPluginIds.contains("notion"))

        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        XCTAssertFalse(
            sut.unplacedPluginIds.contains("notion"),
            "위젯 추가 후 해당 플러그인이 미배치 목록에서 제거되어야 합니다"
        )
    }

    func testAddWidget_InsertsRowInDatabase() throws {
        // Arrange
        let countBefore = try dbManager.fetchWidgetLayouts().count

        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        let countAfter = try dbManager.fetchWidgetLayouts().count
        XCTAssertEqual(
            countAfter,
            countBefore + 1,
            "위젯 추가 후 DB의 widget_layout 레코드 수가 1 증가해야 합니다"
        )
    }

    func testAddWidget_WithAlreadyPlacedPlugin_ThrowsError() {
        // Arrange: "slack"은 이미 배치됨

        // Act & Assert
        XCTAssertThrowsError(
            try sut.addWidget(pluginId: "slack"),
            "이미 배치된 플러그인을 추가 시 오류가 발생해야 합니다"
        )
    }

    func testAddWidget_NewWidget_HasCorrectOrderValue() throws {
        // Arrange
        let lastOrder = sut.editingWidgets.map { $0.order }.max() ?? -1

        // Act
        try sut.addWidget(pluginId: "notion")

        // Assert
        let added = sut.editingWidgets.first { $0.pluginId == "notion" }!
        XCTAssertEqual(
            added.order,
            lastOrder + 1,
            "새로 추가된 위젯의 order는 기존 최대값 + 1이어야 합니다"
        )
    }

    // MARK: - Save and Exit Tests

    func testSaveAndExit_Success_SetsShowSaveFailureToastFalse() async throws {
        // Act
        try await sut.saveAndExit()

        // Assert
        XCTAssertFalse(
            sut.showSaveFailureToast,
            "저장 성공 시 showSaveFailureToast가 false여야 합니다"
        )
    }

    func testSaveAndExit_PersistsCurrentWidgetStateToDB() async throws {
        // Arrange: slack 위젯을 medium으로 변경
        let slackWidget = sut.editingWidgets.first { $0.pluginId == "slack" }!
        try sut.changeWidgetSize(widgetId: slackWidget.stableId, to: "medium")

        // Act
        try await sut.saveAndExit()

        // Assert: DB에서 직접 읽어서 확인
        guard let id = sut.editingWidgets.first(where: { $0.pluginId == "slack" })?.id else {
            // saveAndExit 후에도 id 접근이 가능해야 하므로, DB에서 직접 조회
            let allLayouts = try dbManager.fetchWidgetLayouts()
            let slackLayout = allLayouts.first { $0.pluginId == "slack" }
            XCTAssertEqual(
                slackLayout?.size,
                "medium",
                "saveAndExit 후 DB에서 slack 위젯 size가 'medium'으로 저장되어야 합니다"
            )
            return
        }
        let dbLayout = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(
            dbLayout?.size,
            "medium",
            "saveAndExit 후 DB에서 slack 위젯 size가 'medium'으로 저장되어야 합니다"
        )
    }

    func testSaveAndExit_PreservesWidgetOrderInDB() async throws {
        // Arrange: 순서를 변경
        try sut.reorderWidgets(fromIndex: 0, toIndex: 2)

        // Act
        try await sut.saveAndExit()

        // Assert: DB order가 editingWidgets의 현재 순서와 일치해야 합니다
        let dbWidgets = try dbManager.fetchWidgetLayouts()
        for (index, widget) in sut.editingWidgets.enumerated() {
            let dbWidget = dbWidgets.first { $0.pluginId == widget.pluginId }
            XCTAssertEqual(
                dbWidget?.order,
                index,
                "\(widget.pluginId) 위젯의 DB order가 현재 인덱스 \(index)와 일치해야 합니다"
            )
        }
    }

    // MARK: - Save Failure Toast Tests

    func testShowSaveFailureToast_AfterSaveError_BecomesTrue() async {
        // Arrange: 저장 실패를 시뮬레이션하기 위해 errorDB ViewModel 생성
        let errorDBManager = ClosedDatabaseManager()
        let failSut = EditModeViewModel(
            widgets: makeWidgets(),
            allPluginIds: makeAllPluginIds(),
            dbManager: errorDBManager
        )

        // Act
        try? await failSut.saveAndExit()

        // Assert
        XCTAssertTrue(
            failSut.showSaveFailureToast,
            "저장 실패 시 showSaveFailureToast가 true여야 합니다"
        )
    }

    func testShowSaveFailureToast_AfterSuccessfulSave_IsFalse() async throws {
        // Arrange: 이전에 토스트가 표시된 상태를 시뮬레이션
        sut.showSaveFailureToast = true

        // Act: 재저장 성공
        try await sut.saveAndExit()

        // Assert
        XCTAssertFalse(
            sut.showSaveFailureToast,
            "저장 성공 시 showSaveFailureToast가 false로 리셋되어야 합니다"
        )
    }

    // MARK: - Drag State Tests

    func testSetDragging_WithValidId_SetsDraggingTrue() {
        // Arrange
        let target = sut.editingWidgets.first!

        // Act
        sut.setDragging(widgetId: target.stableId)

        // Assert
        XCTAssertTrue(
            sut.isDragging,
            "드래그 시작 시 isDragging이 true여야 합니다"
        )
    }

    func testSetDragging_WithValidId_SetsDraggingWidgetId() {
        // Arrange
        let target = sut.editingWidgets.first!

        // Act
        sut.setDragging(widgetId: target.stableId)

        // Assert
        XCTAssertEqual(
            sut.draggingWidgetId,
            target.stableId,
            "드래그 중인 위젯 ID가 설정되어야 합니다"
        )
    }

    func testSetDragging_WithNil_SetsDraggingFalse() {
        // Arrange: 드래그 시작
        let target = sut.editingWidgets.first!
        sut.setDragging(widgetId: target.stableId)
        XCTAssertTrue(sut.isDragging)

        // Act: 드래그 종료
        sut.setDragging(widgetId: nil)

        // Assert
        XCTAssertFalse(
            sut.isDragging,
            "드래그 종료 시 isDragging이 false여야 합니다"
        )
    }

    func testSetDragging_WithNil_ClearsDraggingWidgetId() {
        // Arrange: 드래그 시작
        let target = sut.editingWidgets.first!
        sut.setDragging(widgetId: target.stableId)

        // Act: 드래그 종료
        sut.setDragging(widgetId: nil)

        // Assert
        XCTAssertNil(
            sut.draggingWidgetId,
            "드래그 종료 시 draggingWidgetId가 nil이어야 합니다"
        )
    }

    // MARK: - Drag Opacity Tests

    func testDraggingOpacity_ForDraggingWidget_IsReduced() {
        // Arrange
        let target = sut.editingWidgets.first!
        sut.setDragging(widgetId: target.stableId)

        // Act
        let opacity = sut.draggingOpacity(for: target.stableId)

        // Assert
        XCTAssertLessThan(
            opacity,
            1.0,
            "드래그 중인 위젯의 opacity가 1.0 미만이어야 합니다"
        )
    }

    func testDraggingOpacity_ForDraggingWidget_IsGreaterThanZero() {
        // Arrange
        let target = sut.editingWidgets.first!
        sut.setDragging(widgetId: target.stableId)

        // Act
        let opacity = sut.draggingOpacity(for: target.stableId)

        // Assert
        XCTAssertGreaterThan(
            opacity,
            0.0,
            "드래그 중인 위젯의 opacity가 0.0보다 커야 합니다 (완전 투명하면 안 됩니다)"
        )
    }

    func testDraggingOpacity_ForNonDraggingWidget_IsOne() {
        // Arrange
        let dragging = sut.editingWidgets[0]
        let notDragging = sut.editingWidgets[1]
        sut.setDragging(widgetId: dragging.stableId)

        // Act
        let opacity = sut.draggingOpacity(for: notDragging.stableId)

        // Assert
        XCTAssertEqual(
            opacity,
            1.0,
            accuracy: 0.001,
            "드래그 중이 아닌 위젯의 opacity는 1.0이어야 합니다"
        )
    }

    func testDraggingOpacity_WhenNotDragging_AllWidgetsAreFullOpaque() {
        // Arrange: 드래그 없음 (초기 상태)

        // Assert
        for widget in sut.editingWidgets {
            let opacity = sut.draggingOpacity(for: widget.stableId)
            XCTAssertEqual(
                opacity,
                1.0,
                accuracy: 0.001,
                "드래그 상태가 아닐 때 모든 위젯의 opacity는 1.0이어야 합니다. pluginId=\(widget.pluginId)"
            )
        }
    }

    // MARK: - DatabaseManager Extension Tests (updateWidgetSize)

    func testDatabaseManager_UpdateWidgetSize_PersistsChange() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )
        let id = try dbManager.insertWidgetLayout(layout)

        // Act
        try dbManager.updateWidgetSize(id: id, size: "medium")

        // Assert
        let updated = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(
            updated?.size,
            "medium",
            "updateWidgetSize 후 DB에서 size 컬럼이 'medium'이어야 합니다"
        )
    }

    func testDatabaseManager_UpdateWidgetSize_DoesNotChangePosition() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 100.0,
            positionY: 200.0,
            size: "small",
            order: 0
        )
        let id = try dbManager.insertWidgetLayout(layout)

        // Act
        try dbManager.updateWidgetSize(id: id, size: "large")

        // Assert
        let updated = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(updated?.positionX, 100.0, accuracy: 0.001, "크기 변경 시 positionX가 유지되어야 합니다")
        XCTAssertEqual(updated?.positionY, 200.0, accuracy: 0.001, "크기 변경 시 positionY가 유지되어야 합니다")
    }

    func testDatabaseManager_UpdateWidgetSize_AllValidSizes_Succeed() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )
        let id = try dbManager.insertWidgetLayout(layout)
        let validSizes = ["small", "medium", "wide", "large"]

        // Act & Assert
        for size in validSizes {
            XCTAssertNoThrow(
                try dbManager.updateWidgetSize(id: id, size: size),
                "유효한 크기 '\(size)'로 업데이트 시 오류가 없어야 합니다"
            )
            let updated = try dbManager.fetchWidgetLayout(id: id)
            XCTAssertEqual(updated?.size, size, "DB size가 '\(size)'로 업데이트되어야 합니다")
        }
    }

    // MARK: - DatabaseManager Extension Tests (updateWidgetOrder)

    func testDatabaseManager_UpdateWidgetOrder_PersistsChange() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )
        let id = try dbManager.insertWidgetLayout(layout)

        // Act
        try dbManager.updateWidgetOrder(id: id, order: 5)

        // Assert
        let updated = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(
            updated?.order,
            5,
            "updateWidgetOrder 후 DB에서 order 컬럼이 5이어야 합니다"
        )
    }

    func testDatabaseManager_UpdateWidgetOrder_DoesNotChangeSizeOrPosition() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 50.0,
            positionY: 75.0,
            size: "large",
            order: 0
        )
        let id = try dbManager.insertWidgetLayout(layout)

        // Act
        try dbManager.updateWidgetOrder(id: id, order: 3)

        // Assert
        let updated = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(updated?.size, "large", "order 변경 시 size가 유지되어야 합니다")
        XCTAssertEqual(updated?.positionX, 50.0, accuracy: 0.001, "order 변경 시 positionX가 유지되어야 합니다")
        XCTAssertEqual(updated?.positionY, 75.0, accuracy: 0.001, "order 변경 시 positionY가 유지되어야 합니다")
    }

    func testDatabaseManager_UpdateWidgetOrder_ZeroOrder_Succeeds() throws {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 5
        )
        let id = try dbManager.insertWidgetLayout(layout)

        // Act
        try dbManager.updateWidgetOrder(id: id, order: 0)

        // Assert
        let updated = try dbManager.fetchWidgetLayout(id: id)
        XCTAssertEqual(updated?.order, 0, "order를 0으로 업데이트할 수 있어야 합니다")
    }

    // MARK: - EditTitleBar State Tests

    func testEditTitleBarTitle_IsWidgetEditLabel() {
        // Assert
        XCTAssertEqual(
            sut.titleBarTitle,
            "위젯 편집",
            "편집 모드 타이틀은 '위젯 편집'이어야 합니다"
        )
    }

    func testEditTitleBarAddButtonLabel_IsAddWidgetLabel() {
        // Assert
        XCTAssertEqual(
            sut.addButtonLabel,
            "+ 위젯 추가",
            "추가 버튼 레이블은 '+ 위젯 추가'이어야 합니다"
        )
    }

    func testEditTitleBarDoneButtonLabel_IsDoneLabel() {
        // Assert
        XCTAssertEqual(
            sut.doneButtonLabel,
            "완료",
            "완료 버튼 레이블은 '완료'이어야 합니다"
        )
    }

    // MARK: - Unplaced Plugin List Tests

    func testUnplacedPluginIds_AfterAddAndRemove_IsCorrect() throws {
        // Arrange: notion 추가 후 다시 삭제

        // Act 1: notion 추가
        try sut.addWidget(pluginId: "notion")
        XCTAssertFalse(sut.unplacedPluginIds.contains("notion"), "추가 후 미배치 목록에서 제거되어야 합니다")

        // Act 2: notion 위젯 삭제
        let notionWidget = sut.editingWidgets.first { $0.pluginId == "notion" }!
        try sut.removeWidget(widgetId: notionWidget.stableId)

        // Assert
        XCTAssertTrue(
            sut.unplacedPluginIds.contains("notion"),
            "삭제 후 notion이 미배치 목록에 다시 추가되어야 합니다"
        )
    }

    func testUnplacedPluginIds_WithAllPluginsPlaced_IsEmpty() throws {
        // Act: 나머지 미배치 플러그인도 모두 추가
        for pluginId in sut.unplacedPluginIds {
            try sut.addWidget(pluginId: pluginId)
        }

        // Assert
        XCTAssertTrue(
            sut.unplacedPluginIds.isEmpty,
            "모든 플러그인이 배치되면 미배치 목록이 비어야 합니다"
        )
    }

    // MARK: - EditableWidgetContainer State Tests

    func testEditingWidgets_ContainCorrectPluginIds() {
        // Arrange
        let expectedIds: Set<String> = ["slack", "github", "jira"]

        // Assert
        let actualIds = Set(sut.editingWidgets.map { $0.pluginId })
        XCTAssertEqual(
            actualIds,
            expectedIds,
            "editingWidgets가 올바른 플러그인 ID 집합을 포함해야 합니다"
        )
    }

    func testEditingWidgets_MaintainsOrderAfterSizeChange() throws {
        // Arrange
        let originalOrder = sut.editingWidgets.map { $0.pluginId }
        let target = sut.editingWidgets[1]

        // Act: 중간 위젯 크기 변경
        try sut.changeWidgetSize(widgetId: target.stableId, to: "large")

        // Assert: 순서는 유지되어야 합니다
        let newOrder = sut.editingWidgets.map { $0.pluginId }
        XCTAssertEqual(
            originalOrder,
            newOrder,
            "크기 변경 후에도 editingWidgets의 순서가 유지되어야 합니다"
        )
    }
}

// MARK: - ClosedDatabaseManager (Test Double)
//
// 저장 실패 시나리오를 시뮬레이션하기 위한 테스트 더블.
// 모든 쓰기 연산에서 에러를 발생시킵니다.

private final class ClosedDatabaseManager: DatabaseManager {

    init() {
        // in-memory DB로 초기화하되, 쓰기 연산을 오버라이드합니다
        try! super.init(inMemory: true)
    }

    override func updateWidgetSize(id: Int64, size: String) throws {
        throw DatabaseError(message: "테스트용 강제 저장 실패")
    }

    override func updateWidgetOrder(id: Int64, order: Int) throws {
        throw DatabaseError(message: "테스트용 강제 저장 실패")
    }

    override func insertWidgetLayout(_ layout: WidgetLayout) throws -> Int64 {
        throw DatabaseError(message: "테스트용 강제 저장 실패")
    }

    override func deleteWidgetLayout(id: Int64) throws {
        throw DatabaseError(message: "테스트용 강제 저장 실패")
    }
}
