import SwiftUI

// MARK: - SizeSelector

/// 위젯 크기 선택 팝오버 뷰.
/// small / medium / wide / large 옵션을 제공하며, 선택된 크기를 accent 색상으로 강조합니다.
struct SizeSelector: View {

    // MARK: - Properties

    let currentSize: String
    let onSelect: (String) -> Void

    private let sizes: [String] = ["small", "medium", "wide", "large"]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("크기 선택")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            Divider()

            ForEach(sizes, id: \.self) { size in
                sizeOptionButton(size: size)
            }

            Spacer(minLength: 8)
        }
        .frame(width: 150)
        .background(AppTheme.surfaceColor)
        .accessibilityIdentifier("widget_size_selector")
    }

    // MARK: - Private

    @ViewBuilder
    private func sizeOptionButton(size: String) -> some View {
        let isSelected = currentSize == size

        Button(action: {
            onSelect(size)
        }) {
            HStack {
                Text(sizeLabel(for: size))
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("size_option_\(size)")
    }

    private func sizeLabel(for size: String) -> String {
        switch size {
        case "small":
            return "Small (1x1)"
        case "medium":
            return "Medium (1x2)"
        case "wide":
            return "Wide (2x1)"
        case "large":
            return "Large (2x2)"
        default:
            return size
        }
    }
}
