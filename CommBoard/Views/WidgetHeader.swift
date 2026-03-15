import SwiftUI

// MARK: - WidgetHeader

/// 위젯 카드 상단 헤더 뷰.
/// 아이콘, 제목, unread 배지, 새로고침 버튼으로 구성됩니다.
struct WidgetHeader: View {

    // MARK: - Properties

    @ObservedObject var viewModel: WidgetHeaderViewModel

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            // 아이콘
            Image(systemName: viewModel.icon)
                .font(.system(size: 14))
                .foregroundColor(.white)

            // 제목
            Text(viewModel.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // unread 배지
            if viewModel.isUnreadBadgeVisible {
                Text(viewModel.unreadBadgeText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }

            // 새로고침 버튼
            Button(action: {
                viewModel.refreshTapped()
            }) {
                Image(systemName: viewModel.isRefreshing ? "arrow.clockwise" : "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(viewModel.isRefreshButtonEnabled ? .white : .gray)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.isRefreshButtonEnabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
