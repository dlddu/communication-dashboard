import XCTest
@testable import CommBoard

// MARK: - 테스트용 Mock 플러그인

final class MockPlugin: PluginProtocol {
    let id: String
    let name: String
    let icon: String
    var config: PluginConfig

    var fetchCallCount: Int = 0
    var testConnectionCallCount: Int = 0
    var fetchResult: Result<[PluginNotification], Error> = .success([])
    var testConnectionResult: Result<Bool, Error> = .success(true)

    init(
        id: String = "mock-plugin",
        name: String = "Mock Plugin",
        icon: String = "bolt",
        config: PluginConfig = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = config
    }

    func fetch() async throws -> [PluginNotification] {
        fetchCallCount += 1
        switch fetchResult {
        case .success(let notifications):
            return notifications
        case .failure(let error):
            throw error
        }
    }

    func testConnection() async throws -> Bool {
        testConnectionCallCount += 1
        switch testConnectionResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - PluginProtocol 테스트

final class PluginProtocolTests: XCTestCase {

    // MARK: - PluginNotification 생성

    func test_pluginNotification_init_setsAllProperties() {
        // Arrange
        let date = Date(timeIntervalSince1970: 1000000)

        // Act
        let notification = PluginNotification(
            pluginId: "slack",
            title: "New Message",
            subtitle: "From Alice",
            body: "Hello, World!",
            timestamp: date,
            metadata: ["channel": "#general"]
        )

        // Assert
        XCTAssertEqual(notification.pluginId, "slack")
        XCTAssertEqual(notification.title, "New Message")
        XCTAssertEqual(notification.subtitle, "From Alice")
        XCTAssertEqual(notification.body, "Hello, World!")
        XCTAssertEqual(notification.timestamp, date)
        XCTAssertEqual(notification.metadata?["channel"], "#general")
    }

    func test_pluginNotification_init_subtitleIsOptional() {
        // Act
        let notification = PluginNotification(pluginId: "test", title: "Title")

        // Assert
        XCTAssertNil(notification.subtitle, "subtitle은 선택적이어야 합니다")
    }

    func test_pluginNotification_init_bodyIsOptional() {
        // Act
        let notification = PluginNotification(pluginId: "test", title: "Title")

        // Assert
        XCTAssertNil(notification.body, "body는 선택적이어야 합니다")
    }

    func test_pluginNotification_init_metadataIsOptional() {
        // Act
        let notification = PluginNotification(pluginId: "test", title: "Title")

        // Assert
        XCTAssertNil(notification.metadata, "metadata는 선택적이어야 합니다")
    }

    func test_pluginNotification_init_timestampDefaultsToNow() {
        // Arrange
        let before = Date()

        // Act
        let notification = PluginNotification(pluginId: "test", title: "Title")
        let after = Date()

        // Assert
        XCTAssertGreaterThanOrEqual(notification.timestamp, before, "timestamp는 현재 시각 이후여야 합니다")
        XCTAssertLessThanOrEqual(notification.timestamp, after, "timestamp는 현재 시각 이전이어야 합니다")
    }

    // MARK: - MockPlugin PluginProtocol 준수 검증

    func test_mockPlugin_conformsToPluginProtocol() {
        // Arrange & Act
        let plugin: any PluginProtocol = MockPlugin()

        // Assert
        XCTAssertEqual(plugin.id, "mock-plugin")
        XCTAssertEqual(plugin.name, "Mock Plugin")
        XCTAssertEqual(plugin.icon, "bolt")
    }

    func test_mockPlugin_fetch_returnsNotifications() async throws {
        // Arrange
        let plugin = MockPlugin()
        let expectedNotifications = [
            PluginNotification(pluginId: "mock-plugin", title: "Test 1"),
            PluginNotification(pluginId: "mock-plugin", title: "Test 2")
        ]
        plugin.fetchResult = .success(expectedNotifications)

        // Act
        let result = try await plugin.fetch()

        // Assert
        XCTAssertEqual(result.count, 2, "2개의 알림이 반환되어야 합니다")
        XCTAssertEqual(result[0].title, "Test 1")
        XCTAssertEqual(result[1].title, "Test 2")
    }

    func test_mockPlugin_fetch_incrementsCallCount() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        _ = try await plugin.fetch()
        _ = try await plugin.fetch()

        // Assert
        XCTAssertEqual(plugin.fetchCallCount, 2, "fetch()가 2번 호출되어야 합니다")
    }

    func test_mockPlugin_fetch_throwsOnError() async {
        // Arrange
        let plugin = MockPlugin()
        let expectedError = NSError(domain: "TestError", code: 42)
        plugin.fetchResult = .failure(expectedError)

        // Act & Assert
        do {
            _ = try await plugin.fetch()
            XCTFail("에러가 발생해야 합니다")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 42, "설정한 에러가 그대로 전달되어야 합니다")
        }
    }

    func test_mockPlugin_testConnection_returnsTrue() async throws {
        // Arrange
        let plugin = MockPlugin()
        plugin.testConnectionResult = .success(true)

        // Act
        let connected = try await plugin.testConnection()

        // Assert
        XCTAssertTrue(connected, "testConnection()은 true를 반환해야 합니다")
    }

    func test_mockPlugin_testConnection_returnsFalse() async throws {
        // Arrange
        let plugin = MockPlugin()
        plugin.testConnectionResult = .success(false)

        // Act
        let connected = try await plugin.testConnection()

        // Assert
        XCTAssertFalse(connected, "testConnection()은 false를 반환해야 합니다")
    }

    func test_mockPlugin_testConnection_throwsOnNetworkError() async {
        // Arrange
        let plugin = MockPlugin()
        let networkError = NSError(domain: "NetworkError", code: -1009)
        plugin.testConnectionResult = .failure(networkError)

        // Act & Assert
        do {
            _ = try await plugin.testConnection()
            XCTFail("네트워크 에러가 발생해야 합니다")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "NetworkError")
        }
    }

    func test_mockPlugin_config_isMutable() {
        // Arrange
        let plugin = MockPlugin(config: ["key": "original"])

        // Act
        plugin.config["key"] = "updated"
        plugin.config["newKey"] = "newValue"

        // Assert
        XCTAssertEqual(plugin.config["key"], "updated", "기존 설정 값이 변경되어야 합니다")
        XCTAssertEqual(plugin.config["newKey"], "newValue", "새 설정 값이 추가되어야 합니다")
    }
}
