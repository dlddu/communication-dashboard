// PluginProtocol - Protocol definition for CommBoard plugins
// This file is a placeholder. Implementation will be added by code-writer.

import Foundation

// MARK: - Plugin result types

struct PluginFetchResult {
    var notifications: [NotificationRecord]
    var fetchedAt: Date
}

enum PluginConnectionStatus {
    case success
    case failure(Error)
}

// MARK: - PluginProtocol stub

protocol PluginProtocol: AnyObject {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var config: PluginConfig { get set }

    func fetch() async throws -> PluginFetchResult
    func testConnection() async throws -> PluginConnectionStatus
}
