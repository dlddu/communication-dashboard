import Foundation

/// Timer 기반으로 플러그인 polling을 관리하는 스케줄러
public final class PluginScheduler {

    public struct ScheduleEntry {
        public let pluginId: String
        public let interval: TimeInterval
        public let timer: Timer
    }

    private var timers: [String: Timer] = [:]
    private var intervals: [String: TimeInterval] = [:]

    /// fetch 결과를 전달하는 핸들러
    public var onFetch: ((String, [PluginNotification]) -> Void)?

    /// 에러를 전달하는 핸들러
    public var onError: ((String, Error) -> Void)?

    public init() {}

    /// 특정 플러그인의 polling을 시작합니다
    /// - Parameters:
    ///   - plugin: polling할 플러그인
    ///   - interval: polling 주기(초)
    public func start(plugin: any PluginProtocol, interval: TimeInterval) {
        // 기존 타이머가 있으면 먼저 중단
        stop(pluginId: plugin.id)

        intervals[plugin.id] = interval

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task {
                do {
                    let notifications = try await plugin.fetch()
                    self.onFetch?(plugin.id, notifications)
                } catch {
                    self.onError?(plugin.id, error)
                }
            }
        }

        timers[plugin.id] = timer
    }

    /// 특정 플러그인의 polling을 중단합니다
    public func stop(pluginId: String) {
        timers[pluginId]?.invalidate()
        timers.removeValue(forKey: pluginId)
        intervals.removeValue(forKey: pluginId)
    }

    /// 모든 polling을 중단합니다
    public func stopAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        intervals.removeAll()
    }

    /// 특정 플러그인이 스케줄링 중인지 확인합니다
    public func isScheduled(pluginId: String) -> Bool {
        return timers[pluginId] != nil
    }

    /// 현재 스케줄링 중인 플러그인 ID 목록
    public var scheduledPluginIds: [String] {
        return Array(timers.keys)
    }

    /// 특정 플러그인의 polling 주기를 반환합니다
    public func interval(for pluginId: String) -> TimeInterval? {
        return intervals[pluginId]
    }

    deinit {
        stopAll()
    }
}
