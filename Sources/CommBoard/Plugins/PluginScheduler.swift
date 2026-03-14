import Foundation

/// 각 플러그인의 독립적인 polling 주기를 Timer 기반으로 관리합니다.
public final class PluginScheduler {
    private var timers: [String: Timer] = [:]
    private let lock = NSLock()

    public init() {}

    deinit {
        // deinit은 lock 없이 직접 정리 (타이머 클로저의 weak self가 nil이 됨)
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    // MARK: - Start

    /// 특정 플러그인에 대한 polling 타이머를 시작합니다.
    /// 이미 실행 중인 경우 기존 타이머를 중지하고 새로 시작합니다.
    /// - Parameters:
    ///   - plugin: polling할 플러그인
    ///   - interval: polling 주기 (초)
    ///   - handler: 타이머 실행 시 호출될 클로저
    public func start(
        plugin: any PluginProtocol,
        interval: TimeInterval,
        handler: @escaping (any PluginProtocol) -> Void
    ) {
        // 기존 타이머를 lock 범위 내에서 무효화하고 제거
        lock.lock()
        let oldTimer = timers[plugin.id]
        timers.removeValue(forKey: plugin.id)
        lock.unlock()

        oldTimer?.invalidate()

        let pluginId = plugin.id

        // 타이머 생성은 lock 밖에서 수행 (RunLoop 등록 시 재진입 방지)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.lock.lock()
            let isActive = self.timers[pluginId] != nil
            self.lock.unlock()
            if isActive {
                handler(plugin)
            }
        }

        // 새 타이머 등록
        lock.lock()
        timers[pluginId] = timer
        lock.unlock()
    }

    // MARK: - Stop

    /// 특정 플러그인의 타이머를 정지합니다.
    /// - Parameter plugin: 정지할 플러그인
    public func stop(plugin: any PluginProtocol) {
        lock.lock()
        let timer = timers.removeValue(forKey: plugin.id)
        lock.unlock()
        timer?.invalidate()
    }

    /// 모든 플러그인 타이머를 정지합니다.
    public func stopAll() {
        lock.lock()
        let allTimers = timers.values.map { $0 }
        timers.removeAll()
        lock.unlock()
        allTimers.forEach { $0.invalidate() }
    }

    // MARK: - Status

    /// 특정 플러그인의 타이머가 실행 중인지 확인합니다.
    /// - Parameter pluginId: 확인할 플러그인 id
    public func isRunning(pluginId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return timers[pluginId] != nil
    }

    /// 현재 실행 중인 타이머 수를 반환합니다.
    public var activeTimerCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return timers.count
    }
}
