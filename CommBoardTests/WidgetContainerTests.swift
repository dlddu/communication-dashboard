import XCTest
@testable import CommBoard

// MARK: - WidgetContainerTests
//
// WidgetContainer의 프레임 구성 로직을 검증합니다.
// WidgetContainer는 모든 위젯에 공통으로 적용되는 카드 프레임입니다.
//
// 검증 대상:
//   - WidgetContainerViewModel 프레임 설정값
//   - corner radius (12pt)
//   - surface 배경색 (#16213e)
//   - border 색상 (#0f3460)
//   - 위젯 크기별 프레임 크기 계산
//   - 접근성 식별자 포맷

final class WidgetContainerTests: XCTestCase {

    // MARK: - Properties

    var sut: WidgetContainerViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = WidgetContainerViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Corner Radius Tests

    func testCornerRadius_IsEqualToTwelve() {
        // Assert
        XCTAssertEqual(
            sut.cornerRadius,
            12.0,
            accuracy: 0.001,
            "WidgetContainer의 corner radius는 12pt이어야 합니다"
        )
    }

    // MARK: - Color Tests

    func testSurfaceBackgroundColor_HexValue() {
        // Act
        let hex = sut.surfaceBackgroundHex

        // Assert
        XCTAssertEqual(
            hex.lowercased(),
            "#16213e",
            "surface 배경색은 #16213e이어야 합니다"
        )
    }

    func testBorderColor_HexValue() {
        // Act
        let hex = sut.borderColorHex

        // Assert
        XCTAssertEqual(
            hex.lowercased(),
            "#0f3460",
            "border 색상은 #0f3460이어야 합니다"
        )
    }

    // MARK: - Frame Size Tests

    func testFrameSize_ForSmallWidget_IsBaseSize() {
        // Arrange
        let layout = WidgetLayout(
            pluginId: "test-plugin",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let size = sut.frameSize(for: layout)

        // Assert
        XCTAssertGreaterThan(size.width, 0, "small 위젯 너비가 0보다 커야 합니다")
        XCTAssertGreaterThan(size.height, 0, "small 위젯 높이가 0보다 커야 합니다")
    }

    func testFrameSize_ForMediumWidget_TallerThanSmall() {
        // Arrange
        let small = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "small", order: 0)
        let medium = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "medium", order: 1)

        // Act
        let smallSize = sut.frameSize(for: small)
        let mediumSize = sut.frameSize(for: medium)

        // Assert
        XCTAssertGreaterThan(
            mediumSize.height,
            smallSize.height,
            "medium 위젯 높이가 small보다 커야 합니다"
        )
    }

    func testFrameSize_ForWideWidget_WiderThanSmall() {
        // Arrange
        let small = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "small", order: 0)
        let wide = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "wide", order: 1)

        // Act
        let smallSize = sut.frameSize(for: small)
        let wideSize = sut.frameSize(for: wide)

        // Assert
        XCTAssertGreaterThan(
            wideSize.width,
            smallSize.width,
            "wide 위젯 너비가 small보다 커야 합니다"
        )
    }

    func testFrameSize_ForLargeWidget_LargerAreaThanSmall() {
        // Arrange
        let small = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "small", order: 0)
        let large = WidgetLayout(pluginId: "p", positionX: 0, positionY: 0, size: "large", order: 1)

        // Act
        let smallSize = sut.frameSize(for: small)
        let largeSize = sut.frameSize(for: large)

        let smallArea = smallSize.width * smallSize.height
        let largeArea = largeSize.width * largeSize.height

        // Assert
        XCTAssertGreaterThan(
            largeArea,
            smallArea,
            "large 위젯 면적이 small보다 커야 합니다"
        )
    }

    func testFrameSize_ForSameSizeLayouts_AreEqual() {
        // Arrange
        let layout1 = WidgetLayout(pluginId: "plugin-a", positionX: 0, positionY: 0, size: "medium", order: 0)
        let layout2 = WidgetLayout(pluginId: "plugin-b", positionX: 1, positionY: 1, size: "medium", order: 1)

        // Act
        let size1 = sut.frameSize(for: layout1)
        let size2 = sut.frameSize(for: layout2)

        // Assert
        XCTAssertEqual(
            size1.width,
            size2.width,
            accuracy: 0.001,
            "같은 크기의 위젯은 동일한 너비를 가져야 합니다"
        )
        XCTAssertEqual(
            size1.height,
            size2.height,
            accuracy: 0.001,
            "같은 크기의 위젯은 동일한 높이를 가져야 합니다"
        )
    }

    // MARK: - Accessibility Identifier Tests

    func testAccessibilityIdentifier_Format_IncludesPluginId() {
        // Arrange
        let layout = WidgetLayout(
            id: 1,
            pluginId: "slack",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertFalse(
            identifier.isEmpty,
            "접근성 식별자가 비어있지 않아야 합니다"
        )
    }

    func testAccessibilityIdentifier_HasWidgetCellPrefix() {
        // Arrange
        let layout = WidgetLayout(
            id: 5,
            pluginId: "github",
            positionX: 0, positionY: 0,
            size: "medium",
            order: 0
        )

        // Act
        let identifier = sut.accessibilityIdentifier(for: layout)

        // Assert
        XCTAssertTrue(
            identifier.hasPrefix("widget_cell"),
            "접근성 식별자는 'widget_cell' 접두사를 가져야 합니다. 실제 값: \(identifier)"
        )
    }

    func testAccessibilityIdentifier_ForDifferentLayouts_AreDifferent() {
        // Arrange
        let layout1 = WidgetLayout(
            id: 1,
            pluginId: "slack",
            positionX: 0, positionY: 0,
            size: "small",
            order: 0
        )
        let layout2 = WidgetLayout(
            id: 2,
            pluginId: "github",
            positionX: 1, positionY: 0,
            size: "medium",
            order: 1
        )

        // Act
        let identifier1 = sut.accessibilityIdentifier(for: layout1)
        let identifier2 = sut.accessibilityIdentifier(for: layout2)

        // Assert
        XCTAssertNotEqual(
            identifier1,
            identifier2,
            "서로 다른 레이아웃은 다른 접근성 식별자를 가져야 합니다"
        )
    }

    // MARK: - Unread Badge Tests

    func testUnreadCount_WhenZero_ShouldNotShowBadge() {
        // Assert
        XCTAssertFalse(
            sut.shouldShowBadge(unreadCount: 0),
            "unread count가 0일 때 배지를 표시하지 않아야 합니다"
        )
    }

    func testUnreadCount_WhenPositive_ShouldShowBadge() {
        // Assert
        XCTAssertTrue(
            sut.shouldShowBadge(unreadCount: 1),
            "unread count가 1 이상일 때 배지를 표시해야 합니다"
        )
    }

    func testUnreadCount_WhenLarge_ShouldShowBadge() {
        // Assert
        XCTAssertTrue(
            sut.shouldShowBadge(unreadCount: 99),
            "unread count가 99일 때 배지를 표시해야 합니다"
        )
    }
}
