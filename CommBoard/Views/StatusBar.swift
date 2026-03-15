import SwiftUI

// MARK: - StatusBar

/// 대시보드 하단 상태바 뷰.
/// 마지막 동기화 시간을 표시합니다.
struct StatusBar: View {

    // MARK: - Properties

    @ObservedObject var viewModel: StatusBarViewModel

    // MARK: - Body

    var body: some View {
        HStack {
            Text(viewModel.lastSyncText)
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier(viewModel.lastSyncAccessibilityIdentifier)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(hex: "#1a1a2e"))
    }
}
