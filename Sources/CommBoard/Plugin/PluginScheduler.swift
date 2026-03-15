// PluginScheduler - Timer-based polling with independent intervals per plugin

import Foundation

// MARK: - PluginScheduler

class PluginScheduler {
    private(set) var scheduledPluginIds: Set<String> = []

    typealias FetchHandler = (any PluginProtocol, PluginFetchResult) -> Void
    typealias ErrorHandler = (any PluginProtocol, Error) -> Void

    var onFetch: FetchHandler?
    var onError: ErrorHandler?

    // Each plugin gets its own DispatchSourceTimer
    private var timers: [String: DispatchSourceTimer] = [:]

    // Serial queue to protect mutable state
    private let stateQueue = DispatchQueue(label: "com.commboard.pluginscheduler.state")

    // Concurrent queue where timer events fire
    private let timerQueue = DispatchQueue(
        label: "com.commboard.pluginscheduler.timers",
        attributes: .concurrent
    )

    func schedule(plugin: any PluginProtocol, interval: TimeInterval) {
        stateQueue.sync {
            // Cancel existing timer if any
            _cancelTimer(for: plugin.id)

            scheduledPluginIds.insert(plugin.id)

            let timer = DispatchSource.makeTimerSource(queue: timerQueue)
            let deadlineNanoseconds = Int(interval * 1_000_000_000)
            timer.schedule(
                deadline: .now() + .nanoseconds(deadlineNanoseconds),
                repeating: interval
            )

            timer.setEventHandler { [weak self] in
                guard let self = self else { return }

                // Check if still scheduled (may have been cancelled)
                let isStillScheduled = self.stateQueue.sync {
                    self.scheduledPluginIds.contains(plugin.id)
                }
                guard isStillScheduled else { return }

                let fetchHandler = self.onFetch
                let errorHandler = self.onError

                Task {
                    do {
                        let result = try await plugin.fetch()
                        fetchHandler?(plugin, result)
                    } catch {
                        errorHandler?(plugin, error)
                    }
                }
            }

            timers[plugin.id] = timer
            timer.resume()
        }
    }

    func unschedule(pluginId: String) {
        stateQueue.sync {
            _cancelTimer(for: pluginId)
            scheduledPluginIds.remove(pluginId)
        }
    }

    func unscheduleAll() {
        stateQueue.sync {
            for id in scheduledPluginIds {
                _cancelTimer(for: id)
            }
            scheduledPluginIds.removeAll()
        }
    }

    func isScheduled(pluginId: String) -> Bool {
        return stateQueue.sync {
            scheduledPluginIds.contains(pluginId)
        }
    }

    // MARK: - Private helpers (must be called within stateQueue)

    private func _cancelTimer(for pluginId: String) {
        if let timer = timers[pluginId] {
            timer.cancel()
            timers.removeValue(forKey: pluginId)
        }
    }
}
