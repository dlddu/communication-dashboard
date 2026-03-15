import XCTest
@testable import CommBoard

final class PluginSchedulerTests: XCTestCase {

    // MARK: - Properties

    private var sut: PluginScheduler!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = PluginScheduler()
    }

    override func tearDown() async throws {
        sut.stop()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Schedule: happy path

    func test_schedule_registers_plugin_id() throws {
        // Act
        try sut.schedule(pluginId: "slack", interval: 60) { _ in }

        // Assert
        XCTAssertTrue(sut.isScheduled(pluginId: "slack"))
    }

    func test_schedule_stores_correct_interval() throws {
        // Act
        try sut.schedule(pluginId: "github", interval: 120) { _ in }

        // Assert
        XCTAssertEqual(sut.interval(for: "github"), 120)
    }

    func test_schedule_multiple_plugins_with_independent_intervals() throws {
        // Act
        try sut.schedule(pluginId: "slack", interval: 30) { _ in }
        try sut.schedule(pluginId: "github", interval: 60) { _ in }
        try sut.schedule(pluginId: "jira", interval: 300) { _ in }

        // Assert
        XCTAssertEqual(sut.interval(for: "slack"), 30)
        XCTAssertEqual(sut.interval(for: "github"), 60)
        XCTAssertEqual(sut.interval(for: "jira"), 300)
    }

    func test_scheduledPluginIds_returns_all_registered_ids() throws {
        // Arrange
        let ids = ["slack", "github", "jira"]
        for id in ids { try sut.schedule(pluginId: id, interval: 60) { _ in } }

        // Act
        let scheduled = sut.scheduledPluginIds().sorted()

        // Assert
        XCTAssertEqual(scheduled, ids.sorted())
    }

    // MARK: - Schedule: error cases

    func test_schedule_duplicate_plugin_id_throws_alreadyScheduled_error() throws {
        // Arrange
        try sut.schedule(pluginId: "slack", interval: 60) { _ in }

        // Act & Assert
        XCTAssertThrowsError(
            try sut.schedule(pluginId: "slack", interval: 30) { _ in }
        ) { error in
            guard case PluginSchedulerError.alreadyScheduled(let id) = error else {
                return XCTFail("Expected alreadyScheduled, got \(error)")
            }
            XCTAssertEqual(id, "slack")
        }
    }

    // MARK: - isScheduled: edge cases

    func test_isScheduled_returns_false_for_unknown_plugin_id() {
        // Act & Assert
        XCTAssertFalse(sut.isScheduled(pluginId: "unknown"))
    }

    func test_interval_returns_nil_for_unscheduled_plugin() {
        // Act & Assert
        XCTAssertNil(sut.interval(for: "unknown"))
    }

    // MARK: - Start / Stop

    func test_isRunning_is_false_before_start() {
        // Assert
        XCTAssertFalse(sut.isRunning)
    }

    func test_isRunning_is_true_after_start() throws {
        // Arrange
        try sut.schedule(pluginId: "slack", interval: 60) { _ in }

        // Act
        sut.start()

        // Assert
        XCTAssertTrue(sut.isRunning)
    }

    func test_isRunning_is_false_after_stop() throws {
        // Arrange
        try sut.schedule(pluginId: "slack", interval: 60) { _ in }
        sut.start()

        // Act
        sut.stop()

        // Assert
        XCTAssertFalse(sut.isRunning)
    }

    func test_start_is_idempotent_when_already_running() throws {
        // Arrange
        try sut.schedule(pluginId: "slack", interval: 60) { _ in }
        sut.start()

        // Act — calling start again should not change state
        sut.start()

        // Assert
        XCTAssertTrue(sut.isRunning)
    }

    func test_stop_is_idempotent_when_not_running() {
        // Act — stop without prior start should not crash
        sut.stop()

        // Assert
        XCTAssertFalse(sut.isRunning)
    }

    // MARK: - Timer Firing

    func test_timer_fires_fetch_handler_with_correct_plugin_id() throws {
        // Arrange
        let expectation = expectation(description: "fetch handler called")
        var capturedPluginId: String?

        try sut.schedule(pluginId: "slack", interval: 0.05) { id in
            capturedPluginId = id
            expectation.fulfill()
        }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 1.0)
        sut.stop()
        XCTAssertEqual(capturedPluginId, "slack")
    }

    func test_each_plugin_receives_its_own_fetch_handler_call() throws {
        // Arrange
        var receivedIds: [String] = []
        let lock = NSLock()
        let slackExpectation = expectation(description: "slack handler called")
        let githubExpectation = expectation(description: "github handler called")

        try sut.schedule(pluginId: "slack", interval: 0.05) { id in
            lock.lock()
            if !receivedIds.contains("slack") {
                receivedIds.append(id)
                slackExpectation.fulfill()
            }
            lock.unlock()
        }
        try sut.schedule(pluginId: "github", interval: 0.05) { id in
            lock.lock()
            if !receivedIds.contains("github") {
                receivedIds.append(id)
                githubExpectation.fulfill()
            }
            lock.unlock()
        }

        // Act
        sut.start()

        // Assert
        wait(for: [slackExpectation, githubExpectation], timeout: 1.0)
        sut.stop()
        XCTAssertTrue(receivedIds.contains("slack"))
        XCTAssertTrue(receivedIds.contains("github"))
    }

    func test_timer_does_not_fire_before_start() throws {
        // Arrange
        var callCount = 0
        try sut.schedule(pluginId: "slack", interval: 0.01) { _ in
            callCount += 1
        }

        // Act — do not call start
        Thread.sleep(forTimeInterval: 0.1)

        // Assert
        XCTAssertEqual(callCount, 0, "handler should not fire before start() is called")
    }

    func test_timer_stops_firing_after_stop() throws {
        // Arrange
        var callCount = 0
        let firstFireExpectation = expectation(description: "fired at least once")
        firstFireExpectation.assertForOverFulfill = false

        try sut.schedule(pluginId: "slack", interval: 0.05) { _ in
            callCount += 1
            firstFireExpectation.fulfill()
        }
        sut.start()

        // Wait for at least one fire
        wait(for: [firstFireExpectation], timeout: 1.0)

        // Act
        sut.stop()
        let countAfterStop = callCount
        Thread.sleep(forTimeInterval: 0.2)

        // Assert — no additional calls after stop
        XCTAssertEqual(callCount, countAfterStop, "handler should not fire after stop()")
    }

    // MARK: - scheduledPluginIds edge case

    func test_scheduledPluginIds_returns_empty_when_nothing_scheduled() {
        // Act
        let ids = sut.scheduledPluginIds()

        // Assert
        XCTAssertTrue(ids.isEmpty)
    }
}
