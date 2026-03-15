import XCTest
@testable import CommBoard

final class PluginSchedulerTests: XCTestCase {

    // MARK: - Setup

    var scheduler: PluginScheduler!

    override func setUp() {
        super.setUp()
        scheduler = PluginScheduler()
    }

    override func tearDown() {
        scheduler.stopAll()
        scheduler = nil
        super.tearDown()
    }

    // MARK: - 초기 상태

    func test_scheduler_initiallyHasNoScheduledPlugins() {
        // Assert
        XCTAssertTrue(scheduler.scheduledPluginIds.isEmpty, "초기화 시 스케줄된 플러그인이 없어야 합니다")
    }

    // MARK: - 스케줄 시작

    func test_start_marksPluginAsScheduled() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        scheduler.start(plugin: plugin, interval: 60)

        // Assert
        XCTAssertTrue(scheduler.isScheduled(pluginId: "slack"), "start() 후 플러그인이 스케줄 상태여야 합니다")
    }

    func test_start_storesInterval() {
        // Arrange
        let plugin = MockPlugin(id: "github")

        // Act
        scheduler.start(plugin: plugin, interval: 30)

        // Assert
        XCTAssertEqual(
            scheduler.interval(for: "github") ?? 0,
            30,
            accuracy: 0.001,
            "설정한 interval이 저장되어야 합니다"
        )
    }

    func test_start_multiplePlugins_allAreScheduled() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")

        // Act
        scheduler.start(plugin: slack, interval: 60)
        scheduler.start(plugin: github, interval: 30)
        scheduler.start(plugin: jira, interval: 120)

        // Assert
        XCTAssertEqual(scheduler.scheduledPluginIds.count, 3, "3개의 플러그인이 스케줄되어야 합니다")
        XCTAssertTrue(scheduler.isScheduled(pluginId: "slack"), "slack이 스케줄 상태여야 합니다")
        XCTAssertTrue(scheduler.isScheduled(pluginId: "github"), "github이 스케줄 상태여야 합니다")
        XCTAssertTrue(scheduler.isScheduled(pluginId: "jira"), "jira가 스케줄 상태여야 합니다")
    }

    func test_start_multiplePlugins_haveIndependentIntervals() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")

        // Act
        scheduler.start(plugin: slack, interval: 60)
        scheduler.start(plugin: github, interval: 300)

        // Assert
        XCTAssertEqual(scheduler.interval(for: "slack") ?? 0, 60, accuracy: 0.001, "slack의 interval은 60초여야 합니다")
        XCTAssertEqual(scheduler.interval(for: "github") ?? 0, 300, accuracy: 0.001, "github의 interval은 300초여야 합니다")
    }

    func test_start_replacesExistingTimerForSamePlugin() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        scheduler.start(plugin: plugin, interval: 60)

        // Act: 다른 interval로 다시 시작
        scheduler.start(plugin: plugin, interval: 30)

        // Assert
        XCTAssertEqual(scheduler.scheduledPluginIds.count, 1, "같은 플러그인 재시작 시 타이머가 1개여야 합니다")
        XCTAssertEqual(
            scheduler.interval(for: "slack") ?? 0,
            30,
            accuracy: 0.001,
            "새 interval로 업데이트되어야 합니다"
        )
    }

    // MARK: - 스케줄 중단

    func test_stop_removesPluginFromSchedule() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        scheduler.start(plugin: plugin, interval: 60)

        // Act
        scheduler.stop(pluginId: "slack")

        // Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "slack"), "stop() 후 플러그인이 스케줄에서 제거되어야 합니다")
    }

    func test_stop_removesIntervalForPlugin() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        scheduler.start(plugin: plugin, interval: 60)

        // Act
        scheduler.stop(pluginId: "slack")

        // Assert
        XCTAssertNil(scheduler.interval(for: "slack"), "stop() 후 interval 정보가 제거되어야 합니다")
    }

    func test_stop_doesNotAffectOtherPlugins() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        scheduler.start(plugin: slack, interval: 60)
        scheduler.start(plugin: github, interval: 30)

        // Act
        scheduler.stop(pluginId: "slack")

        // Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "slack"), "slack이 중단되어야 합니다")
        XCTAssertTrue(scheduler.isScheduled(pluginId: "github"), "github은 계속 스케줄 상태여야 합니다")
    }

    func test_stop_doesNotThrowForUnscheduledPlugin() {
        // Act & Assert
        XCTAssertNoThrow(
            scheduler.stop(pluginId: "nonexistent"),
            "스케줄되지 않은 플러그인 중단은 에러 없이 동작해야 합니다"
        )
    }

    // MARK: - 모두 중단

    func test_stopAll_removesAllScheduledPlugins() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")
        scheduler.start(plugin: slack, interval: 60)
        scheduler.start(plugin: github, interval: 30)
        scheduler.start(plugin: jira, interval: 120)

        // Act
        scheduler.stopAll()

        // Assert
        XCTAssertTrue(scheduler.scheduledPluginIds.isEmpty, "stopAll() 후 스케줄된 플러그인이 없어야 합니다")
    }

    func test_stopAll_removesAllIntervals() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        scheduler.start(plugin: slack, interval: 60)
        scheduler.start(plugin: github, interval: 30)

        // Act
        scheduler.stopAll()

        // Assert
        XCTAssertNil(scheduler.interval(for: "slack"), "stopAll() 후 slack의 interval이 없어야 합니다")
        XCTAssertNil(scheduler.interval(for: "github"), "stopAll() 후 github의 interval이 없어야 합니다")
    }

    func test_stopAll_onEmptyScheduler_doesNotThrow() {
        // Act & Assert
        XCTAssertNoThrow(
            scheduler.stopAll(),
            "비어있는 스케줄러의 stopAll()은 에러 없이 동작해야 합니다"
        )
    }

    // MARK: - isScheduled 확인

    func test_isScheduled_returnsFalseBeforeStart() {
        // Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "slack"), "start() 전에는 false여야 합니다")
    }

    func test_isScheduled_returnsTrueAfterStart() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        scheduler.start(plugin: plugin, interval: 60)

        // Assert
        XCTAssertTrue(scheduler.isScheduled(pluginId: "slack"), "start() 후에는 true여야 합니다")
    }

    func test_isScheduled_returnsFalseAfterStop() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        scheduler.start(plugin: plugin, interval: 60)

        // Act
        scheduler.stop(pluginId: "slack")

        // Assert
        XCTAssertFalse(scheduler.isScheduled(pluginId: "slack"), "stop() 후에는 false여야 합니다")
    }

    // MARK: - interval 조회

    func test_interval_returnsNilForUnscheduledPlugin() {
        // Assert
        XCTAssertNil(scheduler.interval(for: "nonexistent"), "스케줄되지 않은 플러그인의 interval은 nil이어야 합니다")
    }

    func test_interval_returnsCorrectValueAfterStart() {
        // Arrange
        let plugin = MockPlugin(id: "github")
        scheduler.start(plugin: plugin, interval: 150)

        // Assert
        XCTAssertEqual(scheduler.interval(for: "github") ?? 0, 150, accuracy: 0.001, "설정된 interval이 반환되어야 합니다")
    }

    // MARK: - fetch 콜백 검증

    func test_onFetch_isCalledWhenTimerFires() {
        // Arrange
        let plugin = MockPlugin(id: "test-plugin")
        let expectedNotification = PluginNotification(pluginId: "test-plugin", title: "Timer Fired")
        plugin.fetchResult = .success([expectedNotification])

        let fetchExpectation = expectation(description: "onFetch가 호출되어야 합니다")
        fetchExpectation.expectedFulfillmentCount = 1

        var receivedPluginId: String?
        var receivedNotifications: [PluginNotification] = []

        scheduler.onFetch = { pluginId, notifications in
            receivedPluginId = pluginId
            receivedNotifications = notifications
            fetchExpectation.fulfill()
        }

        // Act: 짧은 interval로 시작 (0.1초)
        scheduler.start(plugin: plugin, interval: 0.1)

        // Assert
        wait(for: [fetchExpectation], timeout: 2.0)
        XCTAssertEqual(receivedPluginId, "test-plugin", "올바른 플러그인 ID가 전달되어야 합니다")
        XCTAssertEqual(receivedNotifications.count, 1, "1개의 알림이 전달되어야 합니다")
        XCTAssertEqual(receivedNotifications.first?.title, "Timer Fired")
    }

    func test_onError_isCalledWhenFetchThrows() {
        // Arrange
        let plugin = MockPlugin(id: "failing-plugin")
        let fetchError = NSError(domain: "FetchError", code: 500)
        plugin.fetchResult = .failure(fetchError)

        let errorExpectation = expectation(description: "onError가 호출되어야 합니다")
        errorExpectation.expectedFulfillmentCount = 1

        var receivedPluginId: String?
        var receivedError: Error?

        scheduler.onError = { pluginId, error in
            receivedPluginId = pluginId
            receivedError = error
            errorExpectation.fulfill()
        }

        // Act
        scheduler.start(plugin: plugin, interval: 0.1)

        // Assert
        wait(for: [errorExpectation], timeout: 2.0)
        XCTAssertEqual(receivedPluginId, "failing-plugin", "에러가 발생한 플러그인 ID가 전달되어야 합니다")
        XCTAssertNotNil(receivedError, "에러가 전달되어야 합니다")
    }

    func test_stop_preventsSubsequentFetchCalls() {
        // Arrange
        let plugin = MockPlugin(id: "test-plugin")
        plugin.fetchResult = .success([])

        var fetchCallCount = 0
        scheduler.onFetch = { _, _ in
            fetchCallCount += 1
        }

        // Act: 시작 후 즉시 중단
        scheduler.start(plugin: plugin, interval: 0.1)
        scheduler.stop(pluginId: "test-plugin")

        // Assert: 0.3초 대기 후 fetch가 더 이상 호출되지 않음을 확인
        let waitExpectation = expectation(description: "대기")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 1.0)

        // stop 후 fetchCallCount가 증가하지 않아야 함 (0 또는 1회)
        let countAfterStop = fetchCallCount
        let secondWaitExpectation = expectation(description: "추가 대기")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            secondWaitExpectation.fulfill()
        }
        wait(for: [secondWaitExpectation], timeout: 1.0)

        XCTAssertEqual(fetchCallCount, countAfterStop, "stop() 후 fetch가 추가로 호출되지 않아야 합니다")
    }
}
