import Foundation
@testable import CommBoard

// MARK: - MockPlugin
// A test double that conforms to PluginProtocol for use in unit tests.

final class MockPlugin: PluginProtocol {

    // MARK: - PluginProtocol conformance

    let id: String
    let name: String
    let icon: String
    var config: PluginConfig

    // MARK: - Test control properties

    /// Set to a value to have fetch() return it; leave nil to throw fetchError.
    var fetchResult: PluginFetchResult?

    /// Set to an error to have fetch() throw.
    var fetchError: Error?

    /// Set to a status to have testConnection() return it.
    var connectionStatus: PluginConnectionStatus = .success

    /// Tracks how many times fetch() was called.
    private(set) var fetchCallCount: Int = 0

    /// Tracks how many times testConnection() was called.
    private(set) var testConnectionCallCount: Int = 0

    // MARK: - Initializer

    init(
        id: String = "mock-plugin",
        name: String = "Mock Plugin",
        icon: String = "star",
        config: PluginConfig = PluginConfig(
            id: "mock-plugin",
            name: "Mock Plugin",
            enabled: true,
            settings: [:]
        )
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = config
    }

    // MARK: - PluginProtocol methods

    func fetch() async throws -> PluginFetchResult {
        fetchCallCount += 1
        if let error = fetchError {
            throw error
        }
        if let result = fetchResult {
            return result
        }
        return PluginFetchResult(notifications: [], fetchedAt: Date())
    }

    func testConnection() async throws -> PluginConnectionStatus {
        testConnectionCallCount += 1
        return connectionStatus
    }
}

// MARK: - MockPluginError

enum MockPluginError: Error, Equatable {
    case networkError
    case authenticationFailed
    case rateLimited
}
