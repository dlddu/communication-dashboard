import Foundation

/// 플러그인 등록/조회/활성화를 관리하는 레지스트리
public final class PluginRegistry {

    private var plugins: [String: any PluginProtocol] = [:]
    private var activePluginIds: Set<String> = []

    public init() {}

    /// 플러그인을 등록합니다
    public func register(plugin: any PluginProtocol) {
        plugins[plugin.id] = plugin
    }

    /// ID로 플러그인을 조회합니다
    public func plugin(byId id: String) -> (any PluginProtocol)? {
        return plugins[id]
    }

    /// 활성화된 플러그인 목록
    public var activePlugins: [any PluginProtocol] {
        return activePluginIds.compactMap { plugins[$0] }
    }

    /// 등록된 모든 플러그인 목록
    public var allPlugins: [any PluginProtocol] {
        return Array(plugins.values)
    }

    /// 플러그인을 활성화합니다
    /// - Throws: PluginRegistryError.notFound 등록되지 않은 플러그인인 경우
    public func activate(pluginId: String) throws {
        guard plugins[pluginId] != nil else {
            throw PluginRegistryError.notFound(id: pluginId)
        }
        activePluginIds.insert(pluginId)
    }

    /// 플러그인을 비활성화합니다
    public func deactivate(pluginId: String) {
        activePluginIds.remove(pluginId)
    }

    /// 모든 플러그인을 비활성화합니다
    public func deactivateAll() {
        activePluginIds.removeAll()
    }

    /// 플러그인이 활성화 상태인지 확인합니다
    public func isActive(pluginId: String) -> Bool {
        return activePluginIds.contains(pluginId)
    }
}

public enum PluginRegistryError: Error, Equatable {
    case notFound(id: String)
    case alreadyRegistered(id: String)
}
