import Foundation

/// 플러그인의 주기적 fetch()를 DispatchSourceTimer 기반으로 관리합니다.
final class PluginScheduler {

    // MARK: - Private Types

    private struct ScheduledPlugin {
        let timer: DispatchSourceTimer
        let interval: TimeInterval
    }

    // MARK: - Properties

    private var scheduledPlugins: [String: ScheduledPlugin] = [:]
    private let timerQueue = DispatchQueue(
        label: "com.dlddu.commboard.pluginscheduler.timers",
        attributes: .concurrent
    )
    private let lock = NSLock()

    // MARK: - Init

    init() {}

    // MARK: - Scheduling

    /// 플러그인을 지정된 주기로 스케줄링합니다. fetch()가 주기적으로 호출됩니다.
    func start(plugin: Plugin, interval: TimeInterval) {
        // 이미 실행 중이면 기존 타이머를 먼저 정지합니다
        cancelExisting(pluginId: plugin.id)

        let timer = DispatchSource.makeTimerSource(queue: timerQueue)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(10))

        timer.setEventHandler { [weak plugin] in
            guard let plugin = plugin else { return }
            Task {
                _ = try? await plugin.fetch()
            }
        }

        lock.lock()
        scheduledPlugins[plugin.id] = ScheduledPlugin(timer: timer, interval: interval)
        lock.unlock()

        timer.resume()
    }

    /// 특정 플러그인의 스케줄을 정지합니다.
    func stop(pluginId: String) {
        cancelExisting(pluginId: pluginId)
    }

    /// 모든 플러그인의 스케줄을 정지합니다.
    func stopAll() {
        lock.lock()
        let current = scheduledPlugins
        scheduledPlugins.removeAll()
        lock.unlock()

        for scheduled in current.values {
            scheduled.timer.cancel()
        }
    }

    // MARK: - Status

    /// 플러그인이 현재 스케줄링 중인지 확인합니다.
    func isRunning(pluginId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return scheduledPlugins[pluginId] != nil
    }

    /// 플러그인의 현재 fetch 주기를 반환합니다. 스케줄되지 않은 경우 nil을 반환합니다.
    func interval(for pluginId: String) -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        return scheduledPlugins[pluginId]?.interval
    }

    // MARK: - Private Helpers

    private func cancelExisting(pluginId: String) {
        lock.lock()
        let existing = scheduledPlugins.removeValue(forKey: pluginId)
        lock.unlock()

        existing?.timer.cancel()
    }
}
