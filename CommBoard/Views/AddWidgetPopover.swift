import SwiftUI

// MARK: - AddWidgetPopover

/// 미배치 플러그인 목록을 표시하고 선택하여 위젯을 추가하는 팝오버 뷰.
struct AddWidgetPopover: View {

    // MARK: - Properties

    let unplacedPluginIds: [String]
    let onAdd: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("위젯 추가")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            Divider()

            if unplacedPluginIds.isEmpty {
                Text("추가할 위젯이 없습니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(unplacedPluginIds, id: \.self) { pluginId in
                    pluginRow(pluginId: pluginId)
                }
            }

            Spacer(minLength: 8)
        }
        .frame(width: 180)
        .background(AppTheme.surfaceColor)
        .accessibilityIdentifier("add_widget_popover")
    }

    // MARK: - Private

    @ViewBuilder
    private func pluginRow(pluginId: String) -> some View {
        Button(action: {
            onAdd(pluginId)
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)

                Text(pluginId)
                    .font(.caption)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add_plugin_\(pluginId)")
    }
}
