import XCTest
@testable import CommBoard

final class PluginSchedulerTests: XCTestCase {

    // MARK: - Setup / Teardown

    var scheduler: PluginScheduler!

    override func setUp() {
        super.setUp()
        scheduler = PluginScheduler()
    }

    override func tearDown() {
        scheduler.unscheduleAll()
        scheduler = nil
        super.tearDown()
    }

    // MARK: - Scheduling

    func test_schedule_marksPluginAsScheduled() {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")

        // Act
        scheduler.schedule(plugin: plugin, interval: 60)

        // Assert
        XCTAssertTrue(scheduler.isScheduled(pluginId: "slack"))
    }

    func test_schedule_multiplePlugins_allAreScheduled() {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")

        // Act
        scheduler.schedule(plugin: slack, interval: 30)
        scheduler.schedule(plugin: github, interval: 60)

        // Assert
        XCTAssertTrue(scheduler.isScheduled(pluginId: "slack"))
        XCTAssertTrue(scheduler.isScheduled(pluginId: "github"))
        XCTAssertEqual(scheduler.scheduledPluginIds.count, 2)
    }

    // MARK: - Unscheduling

    func test_unschedule_removesPluginFromScheduledSet() {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        scheduler.schedule(plugin: plugin, interval: 60)

        // Act
        scheduler.unschedule(pluginId: "slack")

        // Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "slack"))
    }

    func test_unschedule_nonexistentPlugin_doesNotThrow() {
        // Act & Assert: should not throw or crash
        XCTAssertNoThrow(scheduler.unschedule(pluginId: "nonexistent"))
    }

    func test_unscheduleAll_removesAllScheduledPlugins() {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")
        scheduler.schedule(plugin: slack, interval: 30)
        scheduler.schedule(plugin: github, interval: 60)

        // Act
        scheduler.unscheduleAll()

        // Assert
        XCTAssertTrue(scheduler.scheduledPluginIds.isEmpty)
    }

    func test_isScheduled_returnsFalse_whenNotScheduled() {
        // Act & Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "nope"))
    }

    // MARK: - Polling behavior (async / XCTestExpectation)

    func test_scheduler_callsFetchHandler_whenIntervalElapses() {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        let expectation = expectation(description: "fetch handler should be called at least once")
        expectation.assertForOverFulfill = false

        scheduler.onFetch = { _, _ in
            expectation.fulfill()
        }

        // Act: schedule with a very short interval (0.1s) so the test completes quickly
        scheduler.schedule(plugin: plugin, interval: 0.1)

        // Assert: wait up to 2 seconds
        waitForExpectations(timeout: 2.0)
    }

    func test_scheduler_callsFetchHandler_multipleTimesOverInterval() {
        // Arrange
        let plugin = MockPlugin(id: "github", name: "GitHub")
        let expectation = expectation(description: "fetch handler should be called at least 3 times")
        expectation.expectedFulfillmentCount = 3
        expectation.assertForOverFulfill = false

        scheduler.onFetch = { _, _ in
            expectation.fulfill()
        }

        // Act: very short interval to trigger multiple polls quickly
        scheduler.schedule(plugin: plugin, interval: 0.1)

        // Assert: wait long enough for 3 polls (0.1s * 3 = 0.3s, with margin)
        waitForExpectations(timeout: 3.0)
    }

    func test_scheduler_passesCorrectPluginToFetchHandler() {
        // Arrange
        let plugin = MockPlugin(id: "jira", name: "Jira")
        let expectation = expectation(description: "fetch handler should receive the correct plugin")
        expectation.assertForOverFulfill = false

        scheduler.onFetch = { receivedPlugin, _ in
            XCTAssertEqual(receivedPlugin.id, "jira")
            expectation.fulfill()
        }

        // Act
        scheduler.schedule(plugin: plugin, interval: 0.1)

        // Assert
        waitForExpectations(timeout: 2.0)
    }

    func test_scheduler_callsErrorHandler_whenFetchThrows() {
        // Arrange
        let plugin = MockPlugin(id: "failing", name: "Failing Plugin")
        plugin.fetchError = MockPluginError.networkError

        let expectation = expectation(description: "error handler should be called when fetch throws")
        expectation.assertForOverFulfill = false

        scheduler.onError = { receivedPlugin, error in
            XCTAssertEqual(receivedPlugin.id, "failing")
            if let mockError = error as? MockPluginError {
                XCTAssertEqual(mockError, .networkError)
            } else {
                XCTFail("Expected MockPluginError.networkError, got \(error)")
            }
            expectation.fulfill()
        }

        // Act
        scheduler.schedule(plugin: plugin, interval: 0.1)

        // Assert
        waitForExpectations(timeout: 2.0)
    }

    func test_scheduler_stopsCallingFetchHandler_afterUnschedule() {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        var callCountAfterUnschedule = 0
        var hasUnscheduled = false

        let firstFireExpectation = expectation(description: "fetch handler fires before unschedule")
        firstFireExpectation.assertForOverFulfill = false

        scheduler.onFetch = { [weak self] _, _ in
            if !hasUnscheduled {
                hasUnscheduled = true
                self?.scheduler.unschedule(pluginId: "slack")
                firstFireExpectation.fulfill()
            } else {
                callCountAfterUnschedule += 1
            }
        }

        // Act
        scheduler.schedule(plugin: plugin, interval: 0.1)

        // Wait for the first fire and unschedule to happen
        waitForExpectations(timeout: 2.0)

        // Wait an additional period and assert no further calls
        let noMoreCallsExpectation = expectation(description: "no further calls after unschedule")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            noMoreCallsExpectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)

        // Assert
        XCTAssertEqual(callCountAfterUnschedule, 0, "fetch should not be called after unschedule")
    }

    func test_scheduler_eachPlugin_usesItsOwnIndependentInterval() {
        // Arrange
        let fastPlugin = MockPlugin(id: "fast", name: "Fast Plugin")
        let slowPlugin = MockPlugin(id: "slow", name: "Slow Plugin")

        var fastCallCount = 0
        var slowCallCount = 0

        scheduler.onFetch = { plugin, _ in
            if plugin.id == "fast" {
                fastCallCount += 1
            } else if plugin.id == "slow" {
                slowCallCount += 1
            }
        }

        // Act: fast plugin polls every 0.1s, slow plugin polls every 0.4s
        scheduler.schedule(plugin: fastPlugin, interval: 0.1)
        scheduler.schedule(plugin: slowPlugin, interval: 0.4)

        // Wait ~0.5 seconds
        let waitExpectation = expectation(description: "wait for polling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            waitExpectation.fulfill()
        }
        waitForExpectations(timeout: 3.0)

        // Assert: fast plugin should have fired more often than slow plugin
        XCTAssertGreaterThan(fastCallCount, slowCallCount,
            "faster interval should result in more fetch calls: fast=\(fastCallCount) slow=\(slowCallCount)")
    }
}
