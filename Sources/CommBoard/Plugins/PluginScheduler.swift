import Foundation

/// Errors thrown by PluginScheduler operations.
public enum PluginSchedulerError: Error {
    case alreadyScheduled(pluginId: String)
    case pluginNotFound(pluginId: String)
}

/// Coordinates timer-based polling for each registered plugin.
public final class PluginScheduler {
    private var timers: [String: Timer] = [:]
    private var pendingIntervals: [String: TimeInterval] = [:]
    private var fetchHandlers: [String: (String) -> Void] = [:]

    public private(set) var isRunning: Bool = false

    public init() {}

    // MARK: - Scheduling

    /// Schedules a plugin to be polled at the given interval (in seconds).
    /// The `onFetch` closure is called every time the timer fires, passing the plugin id.
    public func schedule(
        pluginId: String,
        interval: TimeInterval,
        onFetch: @escaping (String) -> Void
    ) throws {
        guard pendingIntervals[pluginId] == nil else {
            throw PluginSchedulerError.alreadyScheduled(pluginId: pluginId)
        }
        fetchHandlers[pluginId] = onFetch
        pendingIntervals[pluginId] = interval
    }

    // MARK: - Start / Stop

    /// Starts all scheduled timers. Timers are always created on the main RunLoop
    /// so they fire correctly in both production and XCTest environments.
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        // Capture a snapshot of pending work so stop() can't race with us.
        let intervals = pendingIntervals
        let handlers = fetchHandlers

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isRunning else { return }

            for (pluginId, interval) in intervals {
                // Skip if already created (re-entrant safety).
                guard self.timers[pluginId] == nil else { continue }

                let handler = handlers[pluginId]
                let timer = Timer(
                    timeInterval: interval,
                    repeats: true
                ) { [weak self] _ in
                    guard let self = self, self.isRunning else { return }
                    handler?(pluginId)
                }
                RunLoop.main.add(timer, forMode: .common)
                self.timers[pluginId] = timer
            }
        }
    }

    /// Stops all running timers.
    public func stop() {
        guard isRunning else { return }
        isRunning = false

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Snapshot the dictionary before mutating to avoid concurrent modification.
            let snapshot = self.timers
            self.timers.removeAll()
            for (_, timer) in snapshot {
                timer.invalidate()
            }
        }
    }

    // MARK: - Inspection

    /// Returns true if a timer is scheduled (registered) for the given plugin.
    public func isScheduled(pluginId: String) -> Bool {
        pendingIntervals[pluginId] != nil
    }

    /// Returns the polling interval for the given plugin, or nil if not scheduled.
    public func interval(for pluginId: String) -> TimeInterval? {
        pendingIntervals[pluginId]
    }

    /// Returns the ids of all scheduled plugins.
    public func scheduledPluginIds() -> [String] {
        Array(pendingIntervals.keys)
    }
}
