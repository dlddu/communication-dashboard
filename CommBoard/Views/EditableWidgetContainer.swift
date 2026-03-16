import SwiftUI

// MARK: - EditableWidgetContainer

/// 편집 모드에서 표시되는 위젯 컨테이너.
/// 드래그 핸들, 삭제 버튼, 크기 선택기를 포함합니다.
struct EditableWidgetContainer: View {

    // MARK: - Properties

    let layout: WidgetLayout
    @ObservedObject var containerViewModel: WidgetContainerViewModel
    let opacity: Double
    let onRemove: () -> Void
    let onSizeChange: (String) -> Void
    let onDragStart: () -> Void
    let onDragEnd: () -> Void

    @State private var showSizeSelector: Bool = false

    // MARK: - Body

    var body: some View {
        let size = containerViewModel.frameSize(for: layout)
        let identifier = containerViewModel.accessibilityIdentifier(for: layout)

        ZStack(alignment: .topLeading) {
            // 카드 배경 (dashed border)
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(AppTheme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .strokeBorder(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                        )
                )

            // 카드 내용
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // 드래그 핸들
                    DragHandle()

                    Spacer()

                    // 삭제 버튼
                    RemoveButton(onRemove: onRemove)
                }

                Spacer()

                // 위젯 이름 레이블
                WidgetNameLabel(pluginId: layout.pluginId)

                // 크기 선택기 토글
                Button(action: {
                    showSizeSelector.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10))
                        Text(layout.size)
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("widget_size_selector")
                .popover(isPresented: $showSizeSelector) {
                    SizeSelector(
                        currentSize: layout.size,
                        onSelect: { newSize in
                            onSizeChange(newSize)
                            showSizeSelector = false
                        }
                    )
                }
            }
            .padding(8)
        }
        .frame(width: size.width, height: size.height)
        .opacity(opacity)
        .accessibilityIdentifier(identifier)
        .onDrag {
            onDragStart()
            return NSItemProvider(object: layout.stableId as NSString)
        }
    }
}

// MARK: - DragHandle

/// 드래그 핸들 뷰 (⠿ 텍스트 표시).
struct DragHandle: View {

    var body: some View {
        Text("⠿")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
            .accessibilityIdentifier("widget_drag_handle")
    }
}

// MARK: - RemoveButton

/// 위젯 삭제 버튼 뷰 (✕).
struct RemoveButton: View {

    // MARK: - Properties

    let onRemove: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.red)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("widget_remove_button")
    }
}

// MARK: - WidgetNameLabel

/// 위젯 플러그인 이름 레이블.
struct WidgetNameLabel: View {

    // MARK: - Properties

    let pluginId: String

    // MARK: - Body

    var body: some View {
        Text(pluginId)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.secondary)
            .lineLimit(1)
            .truncationMode(.tail)
            .accessibilityIdentifier("widget_name_label")
    }
}
