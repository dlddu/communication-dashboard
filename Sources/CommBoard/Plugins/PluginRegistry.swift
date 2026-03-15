import Foundation

/// Errors thrown by PluginRegistry operations.
public enum PluginRegistryError: Error, Equatable {
    case duplicatePlugin(id: String)
    case pluginNotFound(id: String)
}

/// Maintains a registry of all available plugins and their activation state.
public final class PluginRegistry {
    private var plugins: [String: any PluginProtocol] = [:]
    private var activePluginIds: Set<String> = []

    public init() {}

    // MARK: - Registration

    /// Registers a plugin. Throws if a plugin with the same id is already registered.
    public func register(_ plugin: any PluginProtocol) throws {
        guard plugins[plugin.id] == nil else {
            throw PluginRegistryError.duplicatePlugin(id: plugin.id)
        }
        plugins[plugin.id] = plugin
    }

    // MARK: - Lookup

    /// Returns the plugin for the given id, or nil if not found.
    public func getPlugin(id: String) -> (any PluginProtocol)? {
        plugins[id]
    }

    /// Returns all registered plugins.
    public func getAllPlugins() -> [any PluginProtocol] {
        Array(plugins.values)
    }

    // MARK: - Activation

    /// Activates the plugin with the given id.
    public func activate(id: String) throws {
        guard plugins[id] != nil else {
            throw PluginRegistryError.pluginNotFound(id: id)
        }
        activePluginIds.insert(id)
    }

    /// Deactivates the plugin with the given id.
    public func deactivate(id: String) throws {
        guard plugins[id] != nil else {
            throw PluginRegistryError.pluginNotFound(id: id)
        }
        activePluginIds.remove(id)
    }

    /// Returns true if the plugin with the given id is active.
    public func isActive(id: String) -> Bool {
        activePluginIds.contains(id)
    }

    /// Returns all currently active plugins.
    public func getActivePlugins() -> [any PluginProtocol] {
        activePluginIds.compactMap { plugins[$0] }
    }
}
