import SwiftUI

// MARK: - WidgetGridView

/// 위젯 그리드 뷰.
/// LazyVGrid 기반 3열 그리드로 위젯을 배치합니다.
struct WidgetGridView: View {

    // MARK: - Properties

    @ObservedObject var gridViewModel: WidgetGridViewModel
    @ObservedObject var containerViewModel: WidgetContainerViewModel

    // MARK: - Body

    var body: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: AppTheme.gridSpacing),
            count: gridViewModel.columnCount
        )

        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                ForEach(gridViewModel.orderedWidgets, id: \.stableId) { layout in
                    widgetCell(for: layout)
                }
            }
            .padding(AppTheme.horizontalPadding)
        }
        .accessibilityIdentifier("dashboard_widget_grid")
    }

    // MARK: - Private

    @ViewBuilder
    private func widgetCell(for layout: WidgetLayout) -> some View {
        let size = containerViewModel.frameSize(for: layout)
        let identifier = containerViewModel.accessibilityIdentifier(for: layout)

        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: containerViewModel.cornerRadius)
                .fill(AppTheme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: containerViewModel.cornerRadius)
                        .stroke(AppTheme.borderColor, lineWidth: 1)
                )
        }
        .frame(width: size.width, height: size.height)
        .accessibilityIdentifier(identifier)
    }
}
