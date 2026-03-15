import Foundation

// MARK: - WidgetGridViewModel

/// WidgetGridView의 그리드 레이아웃 계산 로직을 관리합니다.
/// LazyVGrid 기반 3열 그리드로 위젯을 배치합니다.
///
/// 위젯 크기 체계:
///   - small:  1×1 (columnSpan=1, rowSpan=1)
///   - medium: 1×2 (columnSpan=1, rowSpan=2)
///   - wide:   2×1 (columnSpan=2, rowSpan=1)
///   - large:  2×2 (columnSpan=2, rowSpan=2)
class WidgetGridViewModel: ObservableObject {

    // MARK: - Properties

    /// 그리드 열 수 (3열 고정)
    let columnCount: Int = 3

    /// order 기준 오름차순 정렬된 위젯 목록
    @Published private(set) var orderedWidgets: [WidgetLayout] = []

    // MARK: - Span Calculation

    /// 위젯 크기에 따른 열 스팬을 반환합니다.
    /// - small: 1, medium: 1, wide: 2, large: 2
    /// - 알 수 없는 크기: 기본값 1
    func columnSpan(for layout: WidgetLayout) -> Int {
        switch layout.size {
        case "small":
            return 1
        case "medium":
            return 1
        case "wide":
            return 2
        case "large":
            return 2
        default:
            return 1
        }
    }

    /// 위젯 크기에 따른 행 스팬을 반환합니다.
    /// - small: 1, medium: 2, wide: 1, large: 2
    /// - 알 수 없는 크기: 기본값 1
    func rowSpan(for layout: WidgetLayout) -> Int {
        switch layout.size {
        case "small":
            return 1
        case "medium":
            return 2
        case "wide":
            return 1
        case "large":
            return 2
        default:
            return 1
        }
    }

    /// 위젯의 셀 면적(columnSpan × rowSpan)을 반환합니다.
    func spanArea(for layout: WidgetLayout) -> Int {
        return columnSpan(for: layout) * rowSpan(for: layout)
    }

    // MARK: - Widget Update

    /// 위젯 목록을 order 기준 오름차순으로 정렬하여 업데이트합니다.
    func updateWidgets(_ layouts: [WidgetLayout]) {
        orderedWidgets = layouts.sorted { $0.order < $1.order }
    }

    // MARK: - Accessibility

    /// 위젯 컨테이너의 접근성 식별자를 반환합니다.
    /// 형식: "widget_cell_\(size)"
    func accessibilityIdentifier(for layout: WidgetLayout) -> String {
        return "widget_cell_\(layout.size)"
    }
}
