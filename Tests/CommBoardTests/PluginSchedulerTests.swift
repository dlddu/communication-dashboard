import XCTest
@testable import CommBoard

final class PluginSchedulerTests: XCTestCase {

    // MARK: - Properties

    private var sut: PluginScheduler!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        sut = PluginScheduler()
    }

    override func tearDown() {
        sut.stopAll()
        sut = nil
        super.tearDown()
    }

    // MARK: - 초기 상태 테스트

    func test_initialState_hasZeroActiveTimers() {
        XCTAssertEqual(sut.activeTimerCount, 0)
    }

    func test_isRunning_returnsFalse_whenNotStarted() {
        XCTAssertFalse(sut.isRunning(pluginId: "slack"))
    }

    // MARK: - start(plugin:interval:) 테스트

    func test_start_incrementsActiveTimerCount() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        sut.start(plugin: plugin, interval: 60) { _ in }

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 1)
    }

    func test_start_setsIsRunning_toTrue() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act
        sut.start(plugin: plugin, interval: 60) { _ in }

        // Assert
        XCTAssertTrue(sut.isRunning(pluginId: "slack"))
    }

    func test_start_multiplePlugins_tracksEachIndependently() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")

        // Act
        sut.start(plugin: slack, interval: 30) { _ in }
        sut.start(plugin: github, interval: 60) { _ in }
        sut.start(plugin: jira, interval: 120) { _ in }

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 3)
        XCTAssertTrue(sut.isRunning(pluginId: "slack"))
        XCTAssertTrue(sut.isRunning(pluginId: "github"))
        XCTAssertTrue(sut.isRunning(pluginId: "jira"))
    }

    func test_start_samePlugin_doesNotDuplicateTimer() {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act - 동일 플러그인을 두 번 시작
        sut.start(plugin: plugin, interval: 30) { _ in }
        sut.start(plugin: plugin, interval: 60) { _ in }

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 1)
    }

    func test_start_samePlugin_replacesExistingTimer() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        var callCount = 0

        // Act - 두 번째 시작으로 첫 번째 타이머 교체
        sut.start(plugin: plugin, interval: 0.05) { _ in callCount += 1 }
        sut.start(plugin: plugin, interval: 100) { _ in } // 매우 긴 interval로 교체

        // 잠시 대기 - 첫 번째 타이머가 제거됐다면 콜백이 호출되지 않아야 함
        let expectation = XCTestExpectation(description: "타이머 대기")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // Assert - 첫 번째 타이머가 제거됐으므로 콜백은 0번 호출
        XCTAssertEqual(callCount, 0, "교체된 타이머의 콜백은 호출되지 않아야 합니다")
    }

    func test_start_callsHandler_whenTimerFires() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        let expectation = XCTestExpectation(description: "타이머 핸들러 호출")
        expectation.expectedFulfillmentCount = 1

        // Act
        sut.start(plugin: plugin, interval: 0.05) { firedPlugin in
            XCTAssertEqual(firedPlugin.id, "slack")
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func test_start_passesCorrectPluginToHandler() {
        // Arrange
        let plugin = MockPlugin(id: "github", name: "GitHub Plugin")
        var receivedPlugin: (any PluginProtocol)?
        let expectation = XCTestExpectation(description: "핸들러 플러그인 확인")

        // Act
        sut.start(plugin: plugin, interval: 0.05) { p in
            receivedPlugin = p
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedPlugin?.id, "github")
        XCTAssertEqual(receivedPlugin?.name, "GitHub Plugin")
    }

    // MARK: - stop(plugin:) 테스트

    func test_stop_setsIsRunning_toFalse() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        sut.start(plugin: plugin, interval: 60) { _ in }

        // Act
        sut.stop(plugin: plugin)

        // Assert
        XCTAssertFalse(sut.isRunning(pluginId: "slack"))
    }

    func test_stop_decrementsActiveTimerCount() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        sut.start(plugin: plugin, interval: 60) { _ in }

        // Act
        sut.stop(plugin: plugin)

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 0)
    }

    func test_stop_doesNotAffectOtherTimers() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        sut.start(plugin: slack, interval: 60) { _ in }
        sut.start(plugin: github, interval: 60) { _ in }

        // Act
        sut.stop(plugin: slack)

        // Assert
        XCTAssertFalse(sut.isRunning(pluginId: "slack"))
        XCTAssertTrue(sut.isRunning(pluginId: "github"))
        XCTAssertEqual(sut.activeTimerCount, 1)
    }

    func test_stop_doesNotThrow_whenPluginNotRunning() {
        // Arrange
        let plugin = MockPlugin(id: "nonexistent")

        // Act & Assert - 실행 중이 아닌 플러그인을 정지해도 오류 없음
        sut.stop(plugin: plugin)
        XCTAssertEqual(sut.activeTimerCount, 0)
    }

    func test_stop_preventsHandlerFromBeingCalled() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        var callCount = 0

        sut.start(plugin: plugin, interval: 0.05) { _ in
            callCount += 1
        }

        // Act - 즉시 정지
        sut.stop(plugin: plugin)

        // 타이머가 발동할 충분한 시간 대기
        let expectation = XCTestExpectation(description: "정지 후 대기")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)

        // Assert - 정지 후 핸들러가 호출되지 않아야 함
        XCTAssertEqual(callCount, 0, "정지 후 핸들러는 호출되지 않아야 합니다")
    }

    // MARK: - stopAll() 테스트

    func test_stopAll_clearsAllTimers() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")
        sut.start(plugin: slack, interval: 60) { _ in }
        sut.start(plugin: github, interval: 30) { _ in }
        sut.start(plugin: jira, interval: 120) { _ in }

        // Act
        sut.stopAll()

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 0)
        XCTAssertFalse(sut.isRunning(pluginId: "slack"))
        XCTAssertFalse(sut.isRunning(pluginId: "github"))
        XCTAssertFalse(sut.isRunning(pluginId: "jira"))
    }

    func test_stopAll_doesNotThrow_whenNoTimersRunning() {
        // Act & Assert
        sut.stopAll()
        XCTAssertEqual(sut.activeTimerCount, 0)
    }

    func test_stopAll_allowsRestart_afterStopping() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        sut.start(plugin: plugin, interval: 60) { _ in }
        sut.stopAll()

        // Act
        sut.start(plugin: plugin, interval: 30) { _ in }

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 1)
        XCTAssertTrue(sut.isRunning(pluginId: "slack"))
    }

    // MARK: - 독립 주기 테스트

    func test_eachPlugin_firesAtItsOwnInterval() {
        // Arrange
        let fastPlugin = MockPlugin(id: "fast")
        let slowPlugin = MockPlugin(id: "slow")

        var fastCount = 0
        var slowCount = 0

        let expectation = XCTestExpectation(description: "독립 주기 테스트")

        // Act - fast: 0.05s, slow: 0.15s 간격
        sut.start(plugin: fastPlugin, interval: 0.05) { _ in
            fastCount += 1
        }
        sut.start(plugin: slowPlugin, interval: 0.15) { _ in
            slowCount += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Assert - fast가 slow보다 더 많이 호출됨
        XCTAssertGreaterThan(fastCount, slowCount,
            "짧은 interval의 플러그인이 더 많이 호출되어야 합니다")
        XCTAssertGreaterThan(slowCount, 0,
            "slow 플러그인도 최소 한 번 호출되어야 합니다")
    }

    // MARK: - stop 후 재시작 테스트

    func test_stop_thenStart_resumesTimer() {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        sut.start(plugin: plugin, interval: 60) { _ in }
        sut.stop(plugin: plugin)
        XCTAssertFalse(sut.isRunning(pluginId: "slack"))

        // Act - 정지 후 재시작
        sut.start(plugin: plugin, interval: 30) { _ in }

        // Assert
        XCTAssertTrue(sut.isRunning(pluginId: "slack"))
        XCTAssertEqual(sut.activeTimerCount, 1)
    }

    // MARK: - activeTimerCount 정확성 테스트

    func test_activeTimerCount_isAccurate_afterMixedStartAndStop() {
        // Arrange
        let slack = MockPlugin(id: "slack")
        let github = MockPlugin(id: "github")
        let jira = MockPlugin(id: "jira")

        sut.start(plugin: slack, interval: 60) { _ in }
        sut.start(plugin: github, interval: 60) { _ in }
        sut.start(plugin: jira, interval: 60) { _ in }

        // Act - 일부 정지
        sut.stop(plugin: github)

        // Assert
        XCTAssertEqual(sut.activeTimerCount, 2)
        XCTAssertTrue(sut.isRunning(pluginId: "slack"))
        XCTAssertFalse(sut.isRunning(pluginId: "github"))
        XCTAssertTrue(sut.isRunning(pluginId: "jira"))
    }

    // MARK: - isRunning 정확성 테스트

    func test_isRunning_returnsFalse_forUnknownPluginId_afterOthersStarted() {
        // Arrange - 다른 플러그인이 실행 중일 때
        let slack = MockPlugin(id: "slack")
        sut.start(plugin: slack, interval: 60) { _ in }

        // Act & Assert - 등록되지 않은 id는 false
        XCTAssertFalse(sut.isRunning(pluginId: "github"))
    }
}
