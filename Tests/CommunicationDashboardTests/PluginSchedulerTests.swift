import XCTest
@testable import CommunicationDashboard

// MARK: - SpyPlugin (테스트용 Spy)

final class SpyPlugin: PluginProtocol {
    let id: String
    let name: String
    let icon: String
    let config: PluginConfig

    private(set) var fetchCallCount = 0
    private(set) var testConnectionCallCount = 0

    var fetchDelay: TimeInterval = 0
    var fetchResult: [PluginNotification] = []
    var fetchError: Error?
    var testConnectionResult: Bool = true

    // fetch 호출 시 알림을 위한 continuation
    var onFetch: (() -> Void)?

    init(
        id: String,
        name: String = "Spy Plugin",
        icon: String = "spy.icon",
        interval: Int = 1
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = PluginConfig(id: id, name: name, enabled: true, interval: interval)
    }

    func fetch() async throws -> [PluginNotification] {
        fetchCallCount += 1
        onFetch?()
        if fetchDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchDelay * 1_000_000_000))
        }
        if let error = fetchError {
            throw error
        }
        return fetchResult
    }

    func testConnection() async throws -> Bool {
        testConnectionCallCount += 1
        return testConnectionResult
    }
}

// MARK: - MockSchedulerDelegate

final class MockSchedulerDelegate: PluginSchedulerDelegate {
    private(set) var fetchedNotifications: [String: [PluginNotification]] = [:]
    private(set) var errors: [String: Error] = [:]
    private(set) var didFetchCallCount = 0
    private(set) var didFailCallCount = 0

    var onDidFetch: ((String, [PluginNotification]) -> Void)?
    var onDidFail: ((String, Error) -> Void)?

    func scheduler(
        _ scheduler: PluginScheduler,
        didFetch notifications: [PluginNotification],
        for pluginId: String
    ) {
        didFetchCallCount += 1
        fetchedNotifications[pluginId] = notifications
        onDidFetch?(pluginId, notifications)
    }

    func scheduler(
        _ scheduler: PluginScheduler,
        didFailWith error: Error,
        for pluginId: String
    ) {
        didFailCallCount += 1
        errors[pluginId] = error
        onDidFail?(pluginId, error)
    }
}

// MARK: - PluginSchedulerTests

final class PluginSchedulerTests: XCTestCase {

    private var registry: PluginRegistry!
    private var sut: PluginScheduler!
    private var delegate: MockSchedulerDelegate!

    override func setUp() {
        super.setUp()
        registry = PluginRegistry()
        sut = PluginScheduler(registry: registry, queue: .main)
        delegate = MockSchedulerDelegate()
        sut.delegate = delegate
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        registry = nil
        delegate = nil
        super.tearDown()
    }

    // MARK: - 초기 상태

    func test_init_isNotRunning() {
        // Assert
        XCTAssertFalse(sut.isRunning)
    }

    func test_init_scheduledPluginIdsIsEmpty() {
        // Assert
        XCTAssertTrue(sut.scheduledPluginIds.isEmpty)
    }

    // MARK: - start

    func test_start_setsIsRunningTrue() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        try registry.register(plugin)

        // Act
        sut.start()

        // Assert
        XCTAssertTrue(sut.isRunning)
    }

    func test_start_withNoPlugins_setsIsRunningTrue() {
        // Act
        sut.start()

        // Assert
        XCTAssertTrue(sut.isRunning)
    }

    func test_start_calledTwice_doesNotDuplicate() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        try registry.register(plugin)

        // Act
        sut.start()
        sut.start()

        // Assert - 플러그인이 두 번 스케줄되어서는 안 됩니다
        XCTAssertEqual(sut.scheduledPluginIds.count, 1)
    }

    // MARK: - stop

    func test_stop_afterStart_setsIsRunningFalse() throws {
        // Arrange
        sut.start()

        // Act
        sut.stop()

        // Assert
        XCTAssertFalse(sut.isRunning)
    }

    func test_stop_clearsAllScheduledPlugins() throws {
        // Arrange
        let plugin1 = SpyPlugin(id: "slack", interval: 3600)
        let plugin2 = SpyPlugin(id: "github", interval: 3600)
        try registry.register(plugin1)
        try registry.register(plugin2)
        sut.start()

        // Act
        sut.stop()

        // Assert
        XCTAssertTrue(sut.scheduledPluginIds.isEmpty)
    }

    func test_stop_calledTwice_doesNotCrash() {
        // Arrange
        sut.start()
        sut.stop()

        // Act & Assert - 두 번 stop해도 크래시 없어야 합니다
        XCTAssertNoThrow(sut.stop())
    }

    // MARK: - schedulePlugin - 즉시 fetch 실행

    func test_schedulePlugin_immediatelyCallsFetch() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        let expectation = XCTestExpectation(description: "fetch가 즉시 호출되어야 합니다")
        plugin.onFetch = { expectation.fulfill() }

        // Act
        sut.schedulePlugin(plugin)

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertGreaterThanOrEqual(plugin.fetchCallCount, 1)
    }

    func test_schedulePlugin_addsToPollIds() {
        // Arrange
        let plugin = SpyPlugin(id: "github", interval: 3600)

        // Act
        sut.schedulePlugin(plugin)

        // Assert
        XCTAssertTrue(sut.scheduledPluginIds.contains("github"))
    }

    func test_schedulePlugin_multipleDifferentPlugins_allScheduled() {
        // Arrange
        let plugin1 = SpyPlugin(id: "slack", interval: 3600)
        let plugin2 = SpyPlugin(id: "github", interval: 3600)

        // Act
        sut.schedulePlugin(plugin1)
        sut.schedulePlugin(plugin2)

        // Assert
        XCTAssertTrue(sut.scheduledPluginIds.contains("slack"))
        XCTAssertTrue(sut.scheduledPluginIds.contains("github"))
        XCTAssertEqual(sut.scheduledPluginIds.count, 2)
    }

    // MARK: - start - 활성화된 플러그인만 스케줄

    func test_start_schedulesOnlyEnabledPlugins() throws {
        // Arrange
        let enabledPlugin = SpyPlugin(id: "slack", interval: 3600)
        let disabledPlugin = SpyPlugin(id: "jira", interval: 3600)
        try registry.register(enabledPlugin)
        try registry.register(disabledPlugin)
        try registry.disable(id: "jira")

        // Act
        sut.start()

        // Assert
        XCTAssertTrue(sut.scheduledPluginIds.contains("slack"))
        XCTAssertFalse(sut.scheduledPluginIds.contains("jira"))
    }

    func test_start_withEnabledPlugin_immediatelyFetches() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        try registry.register(plugin)
        let expectation = XCTestExpectation(description: "start 후 즉시 fetch가 호출되어야 합니다")
        plugin.onFetch = { expectation.fulfill() }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - unschedulePlugin

    func test_unschedulePlugin_removesFromScheduledIds() {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        sut.schedulePlugin(plugin)
        XCTAssertTrue(sut.scheduledPluginIds.contains("slack"))

        // Act
        sut.unschedulePlugin(id: "slack")

        // Assert
        XCTAssertFalse(sut.scheduledPluginIds.contains("slack"))
    }

    func test_unschedulePlugin_nonExistentPlugin_doesNotCrash() {
        // Act & Assert
        XCTAssertNoThrow(sut.unschedulePlugin(id: "non-existent"))
    }

    func test_unschedulePlugin_doesNotAffectOtherPlugins() {
        // Arrange
        let plugin1 = SpyPlugin(id: "slack", interval: 3600)
        let plugin2 = SpyPlugin(id: "github", interval: 3600)
        sut.schedulePlugin(plugin1)
        sut.schedulePlugin(plugin2)

        // Act
        sut.unschedulePlugin(id: "slack")

        // Assert
        XCTAssertFalse(sut.scheduledPluginIds.contains("slack"))
        XCTAssertTrue(sut.scheduledPluginIds.contains("github"))
    }

    // MARK: - delegate - didFetch 호출

    func test_delegate_afterFetch_didFetchIsCalled() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        let notification = PluginNotification(
            pluginId: "slack",
            title: "New Message",
            body: "Hello"
        )
        plugin.fetchResult = [notification]
        try registry.register(plugin)

        let expectation = XCTestExpectation(description: "delegate didFetch가 호출되어야 합니다")
        delegate.onDidFetch = { _, _ in expectation.fulfill() }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertGreaterThanOrEqual(delegate.didFetchCallCount, 1)
    }

    func test_delegate_afterFetch_receivesCorrectPluginId() throws {
        // Arrange
        let plugin = SpyPlugin(id: "github", interval: 3600)
        try registry.register(plugin)

        let expectation = XCTestExpectation(description: "올바른 pluginId로 delegate가 호출되어야 합니다")
        var receivedPluginId: String?
        delegate.onDidFetch = { pluginId, _ in
            receivedPluginId = pluginId
            expectation.fulfill()
        }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedPluginId, "github")
    }

    func test_delegate_afterFetch_receivesCorrectNotifications() throws {
        // Arrange
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        let expectedNotification = PluginNotification(
            id: "notif-1",
            pluginId: "slack",
            title: "Test",
            body: "Body"
        )
        plugin.fetchResult = [expectedNotification]
        try registry.register(plugin)

        let expectation = XCTestExpectation(description: "알림 데이터를 올바르게 수신해야 합니다")
        var receivedNotifications: [PluginNotification] = []
        delegate.onDidFetch = { _, notifications in
            receivedNotifications = notifications
            expectation.fulfill()
        }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedNotifications.count, 1)
        XCTAssertEqual(receivedNotifications.first?.title, "Test")
    }

    // MARK: - delegate - didFail 호출

    func test_delegate_whenFetchThrows_didFailIsCalled() throws {
        // Arrange
        struct TestError: Error {}
        let plugin = SpyPlugin(id: "slack", interval: 3600)
        plugin.fetchError = TestError()
        try registry.register(plugin)

        let expectation = XCTestExpectation(description: "fetch 실패 시 didFail이 호출되어야 합니다")
        delegate.onDidFail = { _, _ in expectation.fulfill() }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertGreaterThanOrEqual(delegate.didFailCallCount, 1)
    }

    func test_delegate_whenFetchThrows_receivesCorrectPluginId() throws {
        // Arrange
        struct TestError: Error {}
        let plugin = SpyPlugin(id: "jira", interval: 3600)
        plugin.fetchError = TestError()
        try registry.register(plugin)

        let expectation = XCTestExpectation(description: "실패한 플러그인 ID가 전달되어야 합니다")
        var receivedPluginId: String?
        delegate.onDidFail = { pluginId, _ in
            receivedPluginId = pluginId
            expectation.fulfill()
        }

        // Act
        sut.start()

        // Assert
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedPluginId, "jira")
    }

    // MARK: - 독립적 interval 테스트

    func test_scheduledPluginIds_afterStart_matchesEnabledPluginCount() throws {
        // Arrange
        let plugin1 = SpyPlugin(id: "plugin-1", interval: 3600)
        let plugin2 = SpyPlugin(id: "plugin-2", interval: 7200)
        let plugin3 = SpyPlugin(id: "plugin-3", interval: 1800)
        try registry.register(plugin1)
        try registry.register(plugin2)
        try registry.register(plugin3)

        // Act
        sut.start()

        // Assert
        XCTAssertEqual(sut.scheduledPluginIds.count, 3)
    }
}
