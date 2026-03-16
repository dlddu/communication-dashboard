import SwiftUI

// MARK: - StatusBar

/// 대시보드 하단 상태바 뷰.
/// 마지막 동기화 시간과 플러그인별 polling 주기를 표시합니다.
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

            // 플러그인별 polling 주기 표시
            if !viewModel.pollingIntervals.isEmpty {
                HStack(spacing: 8) {
                    ForEach(viewModel.sortedPollingPluginIds, id: \.self) { pluginId in
                        Text("\(pluginId): \(viewModel.pollingIntervalText(for: pluginId))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .accessibilityIdentifier("status_bar_polling_intervals")
            }
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.vertical, AppTheme.statusBarVerticalPadding)
        .background(AppTheme.backgroundColor)
    }
}
