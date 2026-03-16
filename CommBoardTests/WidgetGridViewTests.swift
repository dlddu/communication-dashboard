import XCTest
@testable import CommBoard

// MARK: - WidgetGridViewTests
//
// WidgetGridView의 그리드 레이아웃 계산 로직을 검증합니다.
// WidgetGridView는 LazyVGrid 기반 3열 그리드로 위젯을 배치합니다.
//
// 위젯 크기 체계:
//   - small:  1×1 (columnSpan=1, rowSpan=1)
//   - medium: 1×2 (columnSpan=1, rowSpan=2)
//   - wide:   2×1 (columnSpan=2, rowSpan=1)
//   - large:  2×2 (columnSpan=2, rowSpan=2)
//
// 검증 대상:
//   - WidgetGridViewModel 위젯 span 계산
//   - 그리드 열 수 (3열)
//   - 크기별 columnSpan / rowSpan 계산
//   - 빈 레이아웃 처리
//   - order 기준 정렬 유지

final class WidgetGridViewTests: XCTestCase {

    // MARK: - Properties

    var sut: WidgetGridViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = WidgetGridViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Grid Column Tests

    func testGridColumnCount_IsThree() {
        // Assert
        XCTAssertEqual(sut.columnCount, 3, "그리드는 3열이어야 합니다")
    }

    // MARK: - Span Calculation: small (1x1)

    func testColumnSpan_ForSmallWidget_IsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "small 위젯의 columnSpan은 1이어야 합니다")
    }

    func testRowSpan_ForSmallWidget_IsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let span = sut.rowSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "small 위젯의 rowSpan은 1이어야 합니다")
    }

    // MARK: - Span Calculation: medium (1x2)

    func testColumnSpan_ForMediumWidget_IsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "medium",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "medium 위젯의 columnSpan은 1이어야 합니다")
    }

    func testRowSpan_ForMediumWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "medium",
            order: 0
        )

        // Act
        let span = sut.rowSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 2, "medium 위젯의 rowSpan은 2이어야 합니다")
    }

    // MARK: - Span Calculation: wide (2x1)

    func testColumnSpan_ForWideWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "wide",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 2, "wide 위젯의 columnSpan은 2이어야 합니다")
    }

    func testRowSpan_ForWideWidget_IsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "wide",
            order: 0
        )

        // Act
        let span = sut.rowSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "wide 위젯의 rowSpan은 1이어야 합니다")
    }

    // MARK: - Span Calculation: large (2x2)

    func testColumnSpan_ForLargeWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "large",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 2, "large 위젯의 columnSpan은 2이어야 합니다")
    }

    func testRowSpan_ForLargeWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "large",
            order: 0
        )

        // Act
        let span = sut.rowSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 2, "large 위젯의 rowSpan은 2이어야 합니다")
    }

    // MARK: - Unknown Size Fallback Tests

    func testColumnSpan_ForUnknownSize_DefaultsToOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "unknown_size",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "알 수 없는 크기의 columnSpan은 1로 기본값이 적용되어야 합니다")
    }

    func testRowSpan_ForUnknownSize_DefaultsToOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "unknown_size",
            order: 0
        )

        // Act
        let span = sut.rowSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "알 수 없는 크기의 rowSpan은 1로 기본값이 적용되어야 합니다")
    }

    func testColumnSpan_ForEmptySize_DefaultsToOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "",
            order: 0
        )

        // Act
        let span = sut.columnSpan(for: layout)

        // Assert
        XCTAssertEqual(span, 1, "빈 크기 문자열의 columnSpan은 1로 기본값이 적용되어야 합니다")
    }

    // MARK: - Widget Order Tests

    func testUpdateWidgets_MaintainsOrderAscending() {
        // Arrange
        let layouts = [
            WidgetLayout(pluginId: "plugin-c", positionX: 0, positionY: 0, size: "small", order: 2),
            WidgetLayout(pluginId: "plugin-a", positionX: 0, positionY: 0, size: "small", order: 0),
            WidgetLayout(pluginId: "plugin-b", positionX: 0, positionY: 0, size: "small", order: 1),
        ]

        // Act
        sut.updateWidgets(layouts)

        // Assert
        XCTAssertEqual(sut.orderedWidgets.count, 3)
        XCTAssertEqual(sut.orderedWidgets[0].order, 0, "첫 번째 위젯의 order는 0이어야 합니다")
        XCTAssertEqual(sut.orderedWidgets[1].order, 1, "두 번째 위젯의 order는 1이어야 합니다")
        XCTAssertEqual(sut.orderedWidgets[2].order, 2, "세 번째 위젯의 order는 2이어야 합니다")
    }

    // MARK: - Empty State Tests

    func testUpdateWidgets_WithEmpty_OrderedWidgetsIsEmpty() {
        // Act
        sut.updateWidgets([])

        // Assert
        XCTAssertTrue(sut.orderedWidgets.isEmpty, "빈 레이아웃을 전달하면 orderedWidgets가 비어야 합니다")
    }

    func testUpdateWidgets_WithSingleWidget_CountIsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "plugin-a",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        sut.updateWidgets([layout])

        // Assert
        XCTAssertEqual(sut.orderedWidgets.count, 1, "위젯 1개가 포함되어야 합니다")
    }

    // MARK: - Span Area Tests

    func testSpanArea_ForSmallWidget_IsOne() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let area = sut.spanArea(for: layout)

        // Assert
        XCTAssertEqual(area, 1, "small 위젯의 셀 면적(1×1)은 1이어야 합니다")
    }

    func testSpanArea_ForMediumWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "medium",
            order: 0
        )

        // Act
        let area = sut.spanArea(for: layout)

        // Assert
        XCTAssertEqual(area, 2, "medium 위젯의 셀 면적(1×2)은 2이어야 합니다")
    }

    func testSpanArea_ForWideWidget_IsTwo() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "wide",
            order: 0
        )

        // Act
        let area = sut.spanArea(for: layout)

        // Assert
        XCTAssertEqual(area, 2, "wide 위젯의 셀 면적(2×1)은 2이어야 합니다")
    }

    func testSpanArea_ForLargeWidget_IsFour() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "large",
            order: 0
        )

        // Act
        let area = sut.spanArea(for: layout)

        // Assert
        XCTAssertEqual(area, 4, "large 위젯의 셀 면적(2×2)은 4이어야 합니다")
    }

    func testSpanArea_SmallLessThanMedium() {
        // Arrange
        let small = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "small", order: 0)
        let medium = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "medium", order: 1)

        // Act
        let smallArea = sut.spanArea(for: small)
        let mediumArea = sut.spanArea(for: medium)

        // Assert
        XCTAssertLessThan(smallArea, mediumArea, "small 면적이 medium 면적보다 작아야 합니다")
    }

    func testSpanArea_MediumLessThanLarge() {
        // Arrange
        let medium = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "medium", order: 0)
        let large = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "large", order: 1)

        // Act
        let mediumArea = sut.spanArea(for: medium)
        let largeArea = sut.spanArea(for: large)

        // Assert
        XCTAssertLessThan(mediumArea, largeArea, "medium 면적이 large 면적보다 작아야 합니다")
    }

    // MARK: - Accessibility Identifier Tests

    func testAccessibilityIdentifier_ForWidgetContainer_HasWidgetCellPrefix() {
        // Arrange
        let layout = WidgetLayout(
            id: 42,
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertTrue(
            identifier.hasPrefix("widget_cell"),
            "위젯 컨테이너의 접근성 식별자는 'widget_cell' 접두사를 가져야 합니다. 실제 값: \(identifier)"
        )
    }

    func testAccessibilityIdentifier_ForSmallWidget_ContainsSmall() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertTrue(
            identifier.contains("small"),
            "small 위젯의 접근성 식별자에 'small'이 포함되어야 합니다. 실제 값: \(identifier)"
        )
    }

    func testAccessibilityIdentifier_ForMediumWidget_ContainsMedium() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "medium",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertTrue(
            identifier.contains("medium"),
            "medium 위젯의 접근성 식별자에 'medium'이 포함되어야 합니다. 실제 값: \(identifier)"
        )
    }

    func testAccessibilityIdentifier_ForLargeWidget_ContainsLarge() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "large",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertTrue(
            identifier.contains("large"),
            "large 위젯의 접근성 식별자에 'large'이 포함되어야 합니다. 실제 값: \(identifier)"
        )
    }

    // MARK: - StableId Tests

    func testStableId_WithDatabaseId_UsesId() {
        // Arrange
        let layout = WidgetLayout(
            id: 42,
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let stableId = layout.stableId

        // Assert
        XCTAssertEqual(stableId, "42", "DB id가 있으면 stableId는 id 문자열이어야 합니다")
    }

    func testStableId_WithoutDatabaseId_UsesPluginIdAndOrder() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 3
        )

        // Act
        let stableId = layout.stableId

        // Assert
        XCTAssertEqual(stableId, "test-plugin_3", "DB id가 없으면 stableId는 pluginId_order 형식이어야 합니다")
    }

    func testStableId_ForDifferentWidgets_AreUnique() {
        // Arrange
        let layout1 = WidgetLayout(pluginId: "slack", positionX: 0, positionY: 0, size: "small", order: 0)
        let layout2 = WidgetLayout(pluginId: "github", positionX: 0, positionY: 0, size: "small", order: 1)

        // Act & Assert
        XCTAssertNotEqual(layout1.stableId, layout2.stableId, "서로 다른 위젯은 다른 stableId를 가져야 합니다")
    }
}
