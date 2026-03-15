import SwiftUI

// MARK: - WidgetContainer

/// 위젯 카드 컨테이너 뷰.
/// 모든 위젯에 공통으로 적용되는 카드 프레임을 제공합니다.
struct WidgetContainer: View {

    // MARK: - Properties

    let layout: WidgetLayout
    @ObservedObject var viewModel: WidgetContainerViewModel

    // MARK: - Body

    var body: some View {
        let size = viewModel.frameSize(for: layout)
        let identifier = viewModel.accessibilityIdentifier(for: layout)

        RoundedRectangle(cornerRadius: viewModel.cornerRadius)
            .fill(Color(hex: viewModel.surfaceBackgroundHex))
            .overlay(
                RoundedRectangle(cornerRadius: viewModel.cornerRadius)
                    .stroke(Color(hex: viewModel.borderColorHex), lineWidth: 1)
            )
            .frame(width: size.width, height: size.height)
            .accessibilityIdentifier(identifier)
    }
}
