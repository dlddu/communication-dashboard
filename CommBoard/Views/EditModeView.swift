import SwiftUI

// MARK: - EditModeView

/// 위젯 편집 모드 뷰.
/// EditTitleBar + 편집 가능한 위젯 그리드를 제공합니다.
struct EditModeView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EditModeViewModel
    @ObservedObject var containerViewModel: WidgetContainerViewModel
    let onDone: () async -> Void

    @State private var showAddPopover: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 편집 타이틀바
            editTitleBar

            // 편집 가능한 위젯 그리드
            editWidgetGrid
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(
            // 저장 실패 Toast
            saveFailureToast,
            alignment: .bottom
        )
    }

    // MARK: - Subviews

    private var editTitleBar: some View {
        HStack {
            Text(viewModel.titleBarTitle)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            // + 위젯 추가 버튼
            Button(action: {
                showAddPopover.toggle()
            }) {
                Text(viewModel.addButtonLabel)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("add_widget_button")
            .popover(isPresented: $showAddPopover) {
                AddWidgetPopover(
                    unplacedPluginIds: viewModel.unplacedPluginIds,
                    onAdd: { pluginId in
                        try? viewModel.addWidget(pluginId: pluginId)
                        showAddPopover = false
                    }
                )
            }

            // 완료 버튼
            Button(action: {
                Task {
                    await onDone()
                }
            }) {
                Text(viewModel.doneButtonLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("edit_done_button")
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.vertical, AppTheme.titleBarVerticalPadding)
        .background(AppTheme.surfaceColor)
    }

    private var editWidgetGrid: some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: AppTheme.gridSpacing),
            count: 3
        )

        return ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.gridSpacing) {
                ForEach(viewModel.editingWidgets, id: \.stableId) { layout in
                    EditableWidgetContainer(
                        layout: layout,
                        containerViewModel: containerViewModel,
                        opacity: viewModel.draggingOpacity(for: layout.stableId),
                        onRemove: {
                            try? viewModel.removeWidget(widgetId: layout.stableId)
                        },
                        onSizeChange: { newSize in
                            try? viewModel.changeWidgetSize(widgetId: layout.stableId, to: newSize)
                        },
                        onDragStart: {
                            viewModel.setDragging(widgetId: layout.stableId)
                        },
                        onDragEnd: {
                            viewModel.setDragging(widgetId: nil)
                        }
                    )
                }
            }
            .padding(AppTheme.horizontalPadding)
        }
        .accessibilityIdentifier("dashboard_widget_grid")
    }

    @ViewBuilder
    private var saveFailureToast: some View {
        if viewModel.showSaveFailureToast {
            Text("저장에 실패했습니다. 다시 시도해주세요.")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.9))
                .cornerRadius(AppTheme.cornerRadius)
                .padding(.bottom, 20)
                .transition(.opacity)
        }
    }
}
