import Foundation

// MARK: - PluginSchedulerDelegate

public protocol PluginSchedulerDelegate: AnyObject {
    func scheduler(_ scheduler: PluginScheduler, didFetch notifications: [PluginNotification], for pluginId: String)
    func scheduler(_ scheduler: PluginScheduler, didFailWith error: Error, for pluginId: String)
}

// MARK: - PluginScheduler

public class PluginScheduler {
    private let registry: PluginRegistry
    private var timers: [String: Timer] = [:]
    private let queue: DispatchQueue

    public weak var delegate: PluginSchedulerDelegate?
    public private(set) var isRunning: Bool = false

    public init(registry: PluginRegistry, queue: DispatchQueue = .global(qos: .background)) {
        self.registry = registry
        self.queue = queue
    }

    /// 모든 활성화된 플러그인에 대해 타이머를 시작합니다.
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        for plugin in registry.listEnabled() {
            schedulePlugin(plugin)
        }
    }

    /// 모든 타이머를 정지합니다.
    public func stop() {
        guard isRunning else { return }
        isRunning = false

        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    /// 특정 플러그인의 타이머를 시작합니다.
    public func schedulePlugin(_ plugin: any PluginProtocol) {
        let interval = TimeInterval(plugin.config.interval)
        let pluginId = plugin.id

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchPlugin(plugin)
        }
        timers[pluginId] = timer

        // 즉시 첫 번째 fetch 실행
        fetchPlugin(plugin)
    }

    /// 특정 플러그인의 타이머를 중단합니다.
    public func unschedulePlugin(id: String) {
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
    }

    /// 현재 스케줄된 플러그인 ID 목록을 반환합니다.
    public var scheduledPluginIds: [String] {
        Array(timers.keys)
    }

    private func fetchPlugin(_ plugin: any PluginProtocol) {
        queue.async { [weak self] in
            guard let self else { return }
            Task {
                do {
                    let notifications = try await plugin.fetch()
                    await MainActor.run {
                        self.delegate?.scheduler(self, didFetch: notifications, for: plugin.id)
                    }
                } catch {
                    await MainActor.run {
                        self.delegate?.scheduler(self, didFailWith: error, for: plugin.id)
                    }
                }
            }
        }
    }
}
