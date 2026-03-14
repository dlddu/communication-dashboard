import XCTest
@testable import CommBoard

// MARK: - Mock Plugin

/// PluginProtocol을 구현하는 테스트용 Mock 플러그인입니다.
final class MockPlugin: PluginProtocol {
    var id: String
    var name: String
    var icon: String
    var isEnabled: Bool
    var config: [String: Any]

    // 동작 제어용 프로퍼티
    var fetchResult: Result<[NotificationRecord], Error> = .success([])
    var testConnectionResult: Result<Bool, Error> = .success(true)
    var fetchCallCount: Int = 0
    var testConnectionCallCount: Int = 0

    init(
        id: String = "mock-plugin",
        name: String = "Mock Plugin",
        icon: String = "star",
        isEnabled: Bool = true,
        config: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isEnabled = isEnabled
        self.config = config
    }

    func fetch() async throws -> [NotificationRecord] {
        fetchCallCount += 1
        return try fetchResult.get()
    }

    func testConnection() async throws -> Bool {
        testConnectionCallCount += 1
        return try testConnectionResult.get()
    }
}

// MARK: - Mock Plugin Error

enum MockPluginError: Error, Equatable {
    case connectionFailed
    case fetchFailed(reason: String)
    case unauthorized
}

// MARK: - PluginProtocol Tests

final class PluginProtocolTests: XCTestCase {

    // MARK: - 기본 프로퍼티 테스트

    func test_mockPlugin_hasCorrectId() {
        // Arrange & Act
        let plugin = MockPlugin(id: "slack")

        // Assert
        XCTAssertEqual(plugin.id, "slack")
    }

    func test_mockPlugin_hasCorrectName() {
        // Arrange & Act
        let plugin = MockPlugin(name: "Slack Plugin")

        // Assert
        XCTAssertEqual(plugin.name, "Slack Plugin")
    }

    func test_mockPlugin_hasCorrectIcon() {
        // Arrange & Act
        let plugin = MockPlugin(icon: "message.fill")

        // Assert
        XCTAssertEqual(plugin.icon, "message.fill")
    }

    func test_mockPlugin_isEnabled_canBeToggled() {
        // Arrange
        let plugin = MockPlugin(isEnabled: true)

        // Act
        plugin.isEnabled = false

        // Assert
        XCTAssertFalse(plugin.isEnabled)
    }

    func test_mockPlugin_config_canBeModified() {
        // Arrange
        let plugin = MockPlugin()

        // Act
        plugin.config["api_key"] = "test-key"
        plugin.config["workspace"] = "my-workspace"

        // Assert
        XCTAssertEqual(plugin.config["api_key"] as? String, "test-key")
        XCTAssertEqual(plugin.config["workspace"] as? String, "my-workspace")
    }

    // MARK: - fetch() 테스트

    func test_fetch_returnsEmptyArray_byDefault() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        let records = try await plugin.fetch()

        // Assert
        XCTAssertTrue(records.isEmpty)
    }

    func test_fetch_returnsConfiguredNotifications() async throws {
        // Arrange
        let plugin = MockPlugin()
        let expectedRecord = NotificationRecord(
            id: "notif-001",
            pluginId: "mock-plugin",
            title: "테스트 알림",
            timestamp: Date()
        )
        plugin.fetchResult = .success([expectedRecord])

        // Act
        let records = try await plugin.fetch()

        // Assert
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, "notif-001")
        XCTAssertEqual(records.first?.title, "테스트 알림")
    }

    func test_fetch_throwsError_whenConfiguredToFail() async {
        // Arrange
        let plugin = MockPlugin()
        plugin.fetchResult = .failure(MockPluginError.fetchFailed(reason: "network error"))

        // Act & Assert
        do {
            _ = try await plugin.fetch()
            XCTFail("오류가 발생해야 합니다")
        } catch MockPluginError.fetchFailed(let reason) {
            XCTAssertEqual(reason, "network error")
        } catch {
            XCTFail("예상치 못한 오류: \(error)")
        }
    }

    func test_fetch_incrementsCallCount() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        _ = try await plugin.fetch()
        _ = try await plugin.fetch()
        _ = try await plugin.fetch()

        // Assert
        XCTAssertEqual(plugin.fetchCallCount, 3)
    }

    func test_fetch_returnsMultipleNotifications() async throws {
        // Arrange
        let plugin = MockPlugin()
        let records = (1...5).map { i in
            NotificationRecord(
                id: "notif-\(i)",
                pluginId: "mock-plugin",
                title: "알림 \(i)",
                timestamp: Date()
            )
        }
        plugin.fetchResult = .success(records)

        // Act
        let fetched = try await plugin.fetch()

        // Assert
        XCTAssertEqual(fetched.count, 5)
    }

    // MARK: - testConnection() 테스트

    func test_testConnection_returnsTrue_byDefault() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        let result = try await plugin.testConnection()

        // Assert
        XCTAssertTrue(result)
    }

    func test_testConnection_returnsFalse_whenConfiguredToFail() async throws {
        // Arrange
        let plugin = MockPlugin()
        plugin.testConnectionResult = .success(false)

        // Act
        let result = try await plugin.testConnection()

        // Assert
        XCTAssertFalse(result)
    }

    func test_testConnection_throwsError_whenConnectionFails() async {
        // Arrange
        let plugin = MockPlugin()
        plugin.testConnectionResult = .failure(MockPluginError.connectionFailed)

        // Act & Assert
        do {
            _ = try await plugin.testConnection()
            XCTFail("오류가 발생해야 합니다")
        } catch MockPluginError.connectionFailed {
            // 예상된 동작
        } catch {
            XCTFail("예상치 못한 오류: \(error)")
        }
    }

    func test_testConnection_incrementsCallCount() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        _ = try await plugin.testConnection()
        _ = try await plugin.testConnection()

        // Assert
        XCTAssertEqual(plugin.testConnectionCallCount, 2)
    }

    func test_testConnection_throwsUnauthorizedError() async {
        // Arrange
        let plugin = MockPlugin()
        plugin.testConnectionResult = .failure(MockPluginError.unauthorized)

        // Act & Assert
        do {
            _ = try await plugin.testConnection()
            XCTFail("오류가 발생해야 합니다")
        } catch MockPluginError.unauthorized {
            // 예상된 동작
        } catch {
            XCTFail("예상치 못한 오류: \(error)")
        }
    }

    // MARK: - PluginProtocol 타입 호환성 테스트

    func test_mockPlugin_conformsToPluginProtocol() {
        // Arrange & Act
        let plugin: any PluginProtocol = MockPlugin()

        // Assert
        XCTAssertNotNil(plugin)
        XCTAssertEqual(plugin.id, "mock-plugin")
    }

    func test_multiplePlugins_canBeStoredAsProtocolType() {
        // Arrange
        let plugins: [any PluginProtocol] = [
            MockPlugin(id: "slack", name: "Slack"),
            MockPlugin(id: "github", name: "GitHub"),
            MockPlugin(id: "jira", name: "Jira")
        ]

        // Assert
        XCTAssertEqual(plugins.count, 3)
        XCTAssertEqual(plugins[0].id, "slack")
        XCTAssertEqual(plugins[1].id, "github")
        XCTAssertEqual(plugins[2].id, "jira")
    }
}
