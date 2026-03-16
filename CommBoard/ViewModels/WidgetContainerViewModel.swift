import Foundation
import CoreGraphics

// MARK: - WidgetContainerViewModel

/// WidgetContainer의 프레임 구성 로직을 관리합니다.
/// 모든 위젯에 공통으로 적용되는 카드 프레임 설정을 담당합니다.
class WidgetContainerViewModel: ObservableObject {

    // MARK: - Style Properties

    /// 위젯 카드의 corner radius (12pt)
    let cornerRadius: CGFloat = AppTheme.cornerRadius

    /// 위젯 카드의 surface 배경색 (hex)
    let surfaceBackgroundHex: String = AppTheme.surfaceHex

    /// 위젯 카드의 border 색상 (hex)
    let borderColorHex: String = AppTheme.borderHex

    // MARK: - Frame Size

    /// 위젯 크기에 따른 프레임 크기를 반환합니다.
    /// - small:  baseWidth × baseHeight (1×1)
    /// - medium: baseWidth × (baseHeight * 2 + gap) (1×2)
    /// - wide:   (baseWidth * 2 + gap) × baseHeight (2×1)
    /// - large:  (baseWidth * 2 + gap) × (baseHeight * 2 + gap) (2×2)
    func frameSize(for layout: WidgetLayout) -> CGSize {
        let baseWidth = AppTheme.widgetBaseWidth
        let baseHeight = AppTheme.widgetBaseHeight
        let gap = AppTheme.gridSpacing
        switch layout.size {
        case "small":
            return CGSize(width: baseWidth, height: baseHeight)
        case "medium":
            return CGSize(width: baseWidth, height: baseHeight * 2 + gap)
        case "wide":
            return CGSize(width: baseWidth * 2 + gap, height: baseHeight)
        case "large":
            return CGSize(width: baseWidth * 2 + gap, height: baseHeight * 2 + gap)
        default:
            return CGSize(width: baseWidth, height: baseHeight)
        }
    }

    // MARK: - Accessibility

    /// 위젯 컨테이너의 접근성 식별자를 반환합니다.
    /// 형식: "widget_cell_\(size)"
    func accessibilityIdentifier(for layout: WidgetLayout) -> String {
        return "widget_cell_\(layout.size)"
    }

    // MARK: - Badge

    /// unread 배지를 표시해야 하는지 반환합니다.
    func shouldShowBadge(unreadCount: Int) -> Bool {
        return unreadCount > 0
    }
}
