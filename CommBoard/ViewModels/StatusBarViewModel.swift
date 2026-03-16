import Foundation

// MARK: - StatusBarViewModel

/// StatusBar의 표시 로직을 관리합니다.
/// 대시보드 하단에 위치하며 마지막 동기화 시간과 플러그인별 polling 주기를 표시합니다.
class StatusBarViewModel: ObservableObject {

    // MARK: - Properties

    /// 마지막 동기화 날짜 (nil이면 동기화된 적 없음)
    @Published var lastSyncDate: Date?

    /// 플러그인별 polling 주기 (pluginId → seconds)
    @Published var pollingIntervals: [String: Int] = [:]

    // MARK: - Computed Properties

    /// 마지막 동기화 시간 표시 텍스트.
    /// lastSyncDate가 nil이면 기본 메시지, 아니면 날짜/시간 포맷 문자열
    var lastSyncText: String {
        guard let date = lastSyncDate else {
            return "동기화 대기 중"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return "마지막 동기화: \(formatter.string(from: date))"
    }

    /// 마지막 동기화 시간 요소의 접근성 식별자
    var lastSyncAccessibilityIdentifier: String {
        return "status_bar_last_sync"
    }

    /// polling 주기가 등록된 플러그인 ID를 알파벳 순으로 반환합니다.
    var sortedPollingPluginIds: [String] {
        pollingIntervals.keys.sorted()
    }

    // MARK: - Polling Intervals

    /// 플러그인별 polling 주기를 업데이트합니다.
    func updatePollingIntervals(_ intervals: [String: Int]) {
        pollingIntervals = intervals
    }

    /// 특정 플러그인의 polling 주기 표시 텍스트를 반환합니다.
    /// 존재하지 않는 플러그인이면 빈 문자열 반환
    func pollingIntervalText(for pluginId: String) -> String {
        guard let seconds = pollingIntervals[pluginId] else {
            return ""
        }
        return formattedInterval(seconds: seconds)
    }

    // MARK: - Update

    /// 마지막 동기화 날짜를 업데이트합니다.
    func updateLastSync(_ date: Date) {
        lastSyncDate = date
    }

    // MARK: - Formatting

    /// 초 단위 주기를 가독성 있는 텍스트로 변환합니다.
    /// - 60초 미만: "N초"
    /// - 60초 이상, 3600초 미만: "N분"
    /// - 3600초 이상: "N시간"
    func formattedInterval(seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)초"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)분"
        } else {
            let hours = seconds / 3600
            return "\(hours)시간"
        }
    }
}
