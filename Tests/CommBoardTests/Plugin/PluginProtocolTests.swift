import XCTest
@testable import CommBoard

final class PluginProtocolTests: XCTestCase {

    // MARK: - Mock Plugin conformance

    func test_mockPlugin_conformsToPluginProtocol() {
        // Arrange & Act
        let plugin: any PluginProtocol = MockPlugin()

        // Assert: basic identity fields are accessible via the protocol
        XCTAssertFalse(plugin.id.isEmpty)
        XCTAssertFalse(plugin.name.isEmpty)
        XCTAssertFalse(plugin.icon.isEmpty)
    }

    func test_mockPlugin_fetch_returnsEmptyNotifications_byDefault() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        let result = try await plugin.fetch()

        // Assert
        XCTAssertTrue(result.notifications.isEmpty)
        XCTAssertNotNil(result.fetchedAt)
    }

    func test_mockPlugin_fetch_returnsConfiguredResult() async throws {
        // Arrange
        let plugin = MockPlugin()
        let now = Date()
        let notification = NotificationRecord(
            id: nil,
            pluginId: plugin.id,
            title: "Test notification",
            subtitle: nil,
            body: "Body text",
            timestamp: now,
            isRead: false,
            metadata: nil,
            createdAt: now
        )
        plugin.fetchResult = PluginFetchResult(notifications: [notification], fetchedAt: now)

        // Act
        let result = try await plugin.fetch()

        // Assert
        XCTAssertEqual(result.notifications.count, 1)
        XCTAssertEqual(result.notifications[0].title, "Test notification")
    }

    func test_mockPlugin_fetch_throwsConfiguredError() async throws {
        // Arrange
        let plugin = MockPlugin()
        plugin.fetchError = MockPluginError.networkError

        // Act & Assert
        do {
            _ = try await plugin.fetch()
            XCTFail("Expected fetch() to throw")
        } catch let error as MockPluginError {
            XCTAssertEqual(error, .networkError)
        }
    }

    func test_mockPlugin_fetch_incrementsCallCount() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        _ = try await plugin.fetch()
        _ = try await plugin.fetch()
        _ = try await plugin.fetch()

        // Assert
        XCTAssertEqual(plugin.fetchCallCount, 3)
    }

    func test_mockPlugin_testConnection_returnsSuccess_byDefault() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        let status = try await plugin.testConnection()

        // Assert
        if case .success = status {
            // pass
        } else {
            XCTFail("Expected .success connection status")
        }
    }

    func test_mockPlugin_testConnection_returnsConfiguredFailure() async throws {
        // Arrange
        let plugin = MockPlugin()
        plugin.connectionStatus = .failure(MockPluginError.authenticationFailed)

        // Act
        let status = try await plugin.testConnection()

        // Assert
        if case .failure(let error) = status, let mockError = error as? MockPluginError {
            XCTAssertEqual(mockError, .authenticationFailed)
        } else {
            XCTFail("Expected .failure with authenticationFailed error")
        }
    }

    func test_mockPlugin_testConnection_incrementsCallCount() async throws {
        // Arrange
        let plugin = MockPlugin()

        // Act
        _ = try await plugin.testConnection()
        _ = try await plugin.testConnection()

        // Assert
        XCTAssertEqual(plugin.testConnectionCallCount, 2)
    }

    // MARK: - PluginConfig mutation via protocol

    func test_pluginProtocol_configIsMutable() {
        // Arrange
        let plugin: any PluginProtocol = MockPlugin()
        let newConfig = PluginConfig(
            id: plugin.id,
            name: plugin.name,
            enabled: false,
            settings: ["key": "value"]
        )

        // Act
        plugin.config = newConfig

        // Assert
        XCTAssertFalse(plugin.config.enabled)
        XCTAssertEqual(plugin.config.settings["key"], "value")
    }
}
