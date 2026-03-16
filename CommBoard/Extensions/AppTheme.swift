import SwiftUI

// MARK: - AppTheme

/// 앱 전체에서 사용하는 다크 테마 색상 및 레이아웃 상수를 중앙 관리합니다.
enum AppTheme {

    // MARK: - Color Hex Constants

    /// 메인 배경색 hex (#1a1a2e)
    static let backgroundHex: String = "#1a1a2e"

    /// 카드/서피스 배경색 hex (#16213e)
    static let surfaceHex: String = "#16213e"

    /// 테두리/강조 색상 hex (#0f3460)
    static let borderHex: String = "#0f3460"

    // MARK: - Color Properties

    /// 메인 배경색
    static var backgroundColor: Color { Color(hex: backgroundHex) }

    /// 카드/서피스 배경색
    static var surfaceColor: Color { Color(hex: surfaceHex) }

    /// 테두리/강조 색상
    static var borderColor: Color { Color(hex: borderHex) }

    // MARK: - Layout Constants

    /// 위젯 카드 corner radius
    static let cornerRadius: CGFloat = 12.0

    /// 위젯 기본 너비
    static let widgetBaseWidth: CGFloat = 160.0

    /// 위젯 기본 높이
    static let widgetBaseHeight: CGFloat = 120.0

    /// 그리드 간격
    static let gridSpacing: CGFloat = 8.0

    /// 수평 패딩
    static let horizontalPadding: CGFloat = 16.0

    /// 수직 패딩 (타이틀바)
    static let titleBarVerticalPadding: CGFloat = 10.0

    /// 수직 패딩 (상태바)
    static let statusBarVerticalPadding: CGFloat = 8.0
}
