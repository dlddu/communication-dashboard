import XCTest
@testable import CommBoard

// MARK: - SpyPlugin
//
// fetch() 호출 횟수와 호출 시각을 기록하는 스파이 플러그인입니다.

final class SpyPlugin: Plugin {

    // MARK: - Protocol Requirements

    let id: String
    let name: String
    let icon: String
    var config: PluginConfig?

    // MARK: - Spy State

    private(set) var fetchCallCount = 0
    private(set) var fetchCallTimestamps: [Date] = []
    var onFetch: (() -> Void)?

    // MARK: - Init

    init(
        id: String = "spy-plugin",
        name: String = "Spy Plugin",
        icon: String = "eye",
        config: PluginConfig? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = config
    }

    // MARK: - Protocol Methods

    func fetch() async throws -> [AppNotification] {
        fetchCallCount += 1
        fetchCallTimestamps.append(Date())
        onFetch?()
        return []
    }

    func testConnection() async throws -> Bool {
        return true
    }
}

// MARK: - PluginSchedulerTests
//
// PluginScheduler는 Timer 기반 polling으로
// 등록된 플러그인의 fetch()를 주기적으로 호출합니다.

final class PluginSchedulerTests: XCTestCase {

    // MARK: - Properties

    var sut: PluginScheduler!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = PluginScheduler()
    }

    override func tearDown() async throws {
        sut.stopAll()
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Start / Stop Tests

    func testStart_DoesNotThrow() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")

        // Act & Assert
        XCTAssertNoThrow(
            sut.start(plugin: plugin, interval: 1.0),
            "스케줄러 시작 시 에러가 발생하면 안 됩니다"
        )
    }

    func testStop_AfterStart_DoesNotThrow() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")
        sut.start(plugin: plugin, interval: 1.0)

        // Act & Assert
        XCTAssertNoThrow(
            sut.stop(pluginId: "plugin-1"),
            "스케줄러 정지 시 에러가 발생하면 안 됩니다"
        )
    }

    func testStop_WithoutStart_DoesNotCrash() {
        // Act & Assert: 시작하지 않은 플러그인 정지 시 크래시가 없어야 합니다
        XCTAssertNoThrow(
            sut.stop(pluginId: "nonexistent-plugin"),
            "시작하지 않은 플러그인 정지 시 에러가 발생하면 안 됩니다"
        )
    }

    func testStopAll_StopsAllScheduledPlugins() {
        // Arrange
        let plugin1 = SpyPlugin(id: "plugin-1")
        let plugin2 = SpyPlugin(id: "plugin-2")
        sut.start(plugin: plugin1, interval: 0.5)
        sut.start(plugin: plugin2, interval: 0.5)

        // Act
        sut.stopAll()

        // Assert
        XCTAssertFalse(sut.isRunning(pluginId: "plugin-1"), "stopAll 후 plugin-1이 정지되어야 합니다")
        XCTAssertFalse(sut.isRunning(pluginId: "plugin-2"), "stopAll 후 plugin-2가 정지되어야 합니다")
    }

    func testIsRunning_ReturnsFalse_BeforeStart() {
        // Assert
        XCTAssertFalse(sut.isRunning(pluginId: "plugin-1"), "시작 전에는 isRunning이 false여야 합니다")
    }

    func testIsRunning_ReturnsTrue_AfterStart() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")

        // Act
        sut.start(plugin: plugin, interval: 60.0)

        // Assert
        XCTAssertTrue(sut.isRunning(pluginId: "plugin-1"), "시작 후에는 isRunning이 true여야 합니다")
    }

    func testIsRunning_ReturnsFalse_AfterStop() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")
        sut.start(plugin: plugin, interval: 60.0)

        // Act
        sut.stop(pluginId: "plugin-1")

        // Assert
        XCTAssertFalse(sut.isRunning(pluginId: "plugin-1"), "정지 후에는 isRunning이 false여야 합니다")
    }

    // MARK: - Per-Plugin Interval Tests

    func testStart_MultiplePlugins_WithDifferentIntervals() {
        // Arrange
        let plugin1 = SpyPlugin(id: "plugin-slow")
        let plugin2 = SpyPlugin(id: "plugin-fast")

        // Act: 서로 다른 주기 설정
        sut.start(plugin: plugin1, interval: 60.0)
        sut.start(plugin: plugin2, interval: 10.0)

        // Assert
        XCTAssertTrue(sut.isRunning(pluginId: "plugin-slow"), "느린 플러그인이 실행 중이어야 합니다")
        XCTAssertTrue(sut.isRunning(pluginId: "plugin-fast"), "빠른 플러그인이 실행 중이어야 합니다")
        XCTAssertNotEqual(
            sut.interval(for: "plugin-slow"),
            sut.interval(for: "plugin-fast"),
            "두 플러그인의 주기가 달라야 합니다"
        )
    }

    func testInterval_ReturnsCorrectValue_AfterStart() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")
        let expectedInterval: TimeInterval = 42.0

        // Act
        sut.start(plugin: plugin, interval: expectedInterval)

        // Assert
        XCTAssertEqual(
            sut.interval(for: "plugin-1"),
            expectedInterval,
            accuracy: 0.001,
            "설정한 주기가 올바르게 반환되어야 합니다"
        )
    }

    func testInterval_ReturnsNil_WhenPluginNotScheduled() {
        // Act & Assert
        XCTAssertNil(
            sut.interval(for: "nonexistent-plugin"),
            "스케줄되지 않은 플러그인의 주기는 nil이어야 합니다"
        )
    }

    func testRestart_WithNewInterval_UpdatesInterval() {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")
        sut.start(plugin: plugin, interval: 30.0)

        // Act: 다른 주기로 재시작
        sut.stop(pluginId: "plugin-1")
        sut.start(plugin: plugin, interval: 90.0)

        // Assert
        XCTAssertEqual(
            sut.interval(for: "plugin-1"),
            90.0,
            accuracy: 0.001,
            "재시작 후 새 주기가 적용되어야 합니다"
        )
    }

    // MARK: - Fetch Invocation Tests

    func testScheduler_InvokesFetch_AfterInterval() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "fetch()가 호출되어야 합니다")
        let plugin = SpyPlugin(id: "plugin-1")
        plugin.onFetch = { expectation.fulfill() }

        // Act: 짧은 주기(0.1초)로 스케줄러 시작
        sut.start(plugin: plugin, interval: 0.1)

        // Assert
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertGreaterThan(plugin.fetchCallCount, 0, "스케줄 주기 후 fetch()가 호출되어야 합니다")
    }

    func testScheduler_InvokesFetch_MultipleTimesOverPeriod() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "fetch()가 여러 번 호출되어야 합니다")
        expectation.expectedFulfillmentCount = 3

        let plugin = SpyPlugin(id: "plugin-1")
        plugin.onFetch = { expectation.fulfill() }

        // Act: 0.1초 주기로 시작, 약 0.5초 대기
        sut.start(plugin: plugin, interval: 0.1)

        // Assert
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(plugin.fetchCallCount, 3, "0.5초 동안 fetch()가 최소 3회 호출되어야 합니다")
    }

    func testScheduler_StopsCallingFetch_AfterStop() async throws {
        // Arrange
        let plugin = SpyPlugin(id: "plugin-1")
        sut.start(plugin: plugin, interval: 0.1)

        // 첫 번째 fetch가 호출될 때까지 대기
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3초
        sut.stop(pluginId: "plugin-1")
        let countAfterStop = plugin.fetchCallCount

        // 정지 후 추가 대기
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3초

        // Assert
        XCTAssertEqual(
            plugin.fetchCallCount,
            countAfterStop,
            "stop() 후에는 추가적인 fetch() 호출이 없어야 합니다"
        )
    }

    func testScheduler_IndependentPlugins_EachFetchedSeparately() async throws {
        // Arrange
        let expectation1 = XCTestExpectation(description: "plugin-1 fetch 호출")
        let expectation2 = XCTestExpectation(description: "plugin-2 fetch 호출")

        let plugin1 = SpyPlugin(id: "plugin-1")
        let plugin2 = SpyPlugin(id: "plugin-2")

        plugin1.onFetch = { expectation1.fulfill() }
        plugin2.onFetch = { expectation2.fulfill() }

        // Act: 두 플러그인을 독립적으로 스케줄
        sut.start(plugin: plugin1, interval: 0.15)
        sut.start(plugin: plugin2, interval: 0.1)

        // Assert
        await fulfillment(of: [expectation1, expectation2], timeout: 3.0)
        XCTAssertGreaterThan(plugin1.fetchCallCount, 0, "plugin-1의 fetch()가 호출되어야 합니다")
        XCTAssertGreaterThan(plugin2.fetchCallCount, 0, "plugin-2의 fetch()가 호출되어야 합니다")
    }

    func testScheduler_OnePluginStop_DoesNotAffectOther() async throws {
        // Arrange
        let expectation = XCTestExpectation(description: "plugin-2 fetch 호출")
        let plugin1 = SpyPlugin(id: "plugin-1")
        let plugin2 = SpyPlugin(id: "plugin-2")

        plugin2.onFetch = { expectation.fulfill() }

        // Act
        sut.start(plugin: plugin1, interval: 0.1)
        sut.start(plugin: plugin2, interval: 0.1)
        sut.stop(pluginId: "plugin-1")

        // Assert: plugin-1이 정지해도 plugin-2는 계속 실행
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertFalse(sut.isRunning(pluginId: "plugin-1"), "plugin-1은 정지 상태여야 합니다")
        XCTAssertTrue(sut.isRunning(pluginId: "plugin-2"), "plugin-2는 계속 실행 중이어야 합니다")
        XCTAssertGreaterThan(plugin2.fetchCallCount, 0, "plugin-2는 계속 fetch()를 호출해야 합니다")
    }
}
