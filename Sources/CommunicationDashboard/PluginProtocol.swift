import Foundation

// MARK: - Notification Model

public struct PluginNotification: Identifiable, Equatable {
    public let id: String
    public let pluginId: String
    public let title: String
    public let subtitle: String?
    public let body: String?
    public let timestamp: Date
    public var isRead: Bool
    public let metadata: [String: String]?

    public init(
        id: String = UUID().uuidString,
        pluginId: String,
        title: String,
        subtitle: String? = nil,
        body: String? = nil,
        timestamp: Date = Date(),
        isRead: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.pluginId = pluginId
        self.title = title
        self.subtitle = subtitle
        self.body = body
        self.timestamp = timestamp
        self.isRead = isRead
        self.metadata = metadata
    }
}

// MARK: - PluginProtocol

public protocol PluginProtocol: AnyObject {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var config: PluginConfig { get }

    func fetch() async throws -> [PluginNotification]
    func testConnection() async throws -> Bool
}
