import Foundation

/// The contract every CommBoard plugin must conform to.
public protocol PluginProtocol: AnyObject {
    /// Unique identifier for this plugin (e.g. "slack", "github").
    var id: String { get }

    /// Human-readable display name.
    var name: String { get }

    /// SF Symbol name or asset name for the plugin icon.
    var icon: String { get }

    /// Arbitrary configuration values loaded from YAML.
    var config: [String: Any] { get }

    /// Fetches new notifications from the plugin's data source.
    func fetch() async throws -> [Notification]

    /// Verifies that the plugin can reach its data source.
    func testConnection() async throws -> Bool
}
