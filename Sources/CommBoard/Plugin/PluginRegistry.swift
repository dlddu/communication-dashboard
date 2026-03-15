// PluginRegistry - Plugin registration, lookup, and activation management

import Foundation

// MARK: - PluginRegistry errors

enum PluginRegistryError: Error, Equatable {
    case pluginAlreadyRegistered(String)
    case pluginNotFound(String)
}

// MARK: - PluginRegistry

class PluginRegistry {
    private(set) var registeredPlugins: [String: any PluginProtocol] = [:]
    private(set) var activePluginIds: Set<String> = []

    func register(_ plugin: any PluginProtocol) throws {
        guard registeredPlugins[plugin.id] == nil else {
            throw PluginRegistryError.pluginAlreadyRegistered(plugin.id)
        }
        registeredPlugins[plugin.id] = plugin
    }

    func unregister(pluginId: String) throws {
        guard registeredPlugins[pluginId] != nil else {
            throw PluginRegistryError.pluginNotFound(pluginId)
        }
        registeredPlugins.removeValue(forKey: pluginId)
        activePluginIds.remove(pluginId)
    }

    func plugin(for id: String) -> (any PluginProtocol)? {
        return registeredPlugins[id]
    }

    func activate(pluginId: String) throws {
        guard registeredPlugins[pluginId] != nil else {
            throw PluginRegistryError.pluginNotFound(pluginId)
        }
        activePluginIds.insert(pluginId)
    }

    func deactivate(pluginId: String) throws {
        guard registeredPlugins[pluginId] != nil else {
            throw PluginRegistryError.pluginNotFound(pluginId)
        }
        activePluginIds.remove(pluginId)
    }

    func isActive(pluginId: String) -> Bool {
        return activePluginIds.contains(pluginId)
    }

    var allPlugins: [any PluginProtocol] {
        Array(registeredPlugins.values)
    }

    var activePlugins: [any PluginProtocol] {
        registeredPlugins.values.filter { activePluginIds.contains($0.id) }
    }
}
