import Foundation

/// 플러그인 등록, 조회, 활성화를 관리합니다.
final class PluginRegistry {

    // MARK: - Properties

    private var plugins: [String: Plugin] = [:]
    private var activePluginIds: Set<String> = []

    // MARK: - Init

    init() {}

    // MARK: - Computed Properties

    /// 등록된 모든 플러그인
    var allPlugins: [Plugin] {
        Array(plugins.values)
    }

    /// 현재 활성화된 플러그인만 반환
    var activePlugins: [Plugin] {
        plugins.values.filter { activePluginIds.contains($0.id) }
    }

    // MARK: - Registration

    /// 플러그인을 등록합니다. 동일 ID가 이미 등록된 경우 덮어씁니다.
    func register(_ plugin: Plugin) {
        plugins[plugin.id] = plugin
    }

    /// 플러그인을 등록 해제합니다. 활성 상태이면 비활성화도 수행합니다.
    func unregister(pluginId: String) {
        plugins.removeValue(forKey: pluginId)
        activePluginIds.remove(pluginId)
    }

    // MARK: - Lookup

    /// ID로 플러그인을 조회합니다.
    func plugin(withId id: String) -> Plugin? {
        plugins[id]
    }

    // MARK: - Activation

    /// 플러그인을 활성화합니다. 등록되지 않은 플러그인은 무시합니다.
    func activate(pluginId: String) {
        guard plugins[pluginId] != nil else { return }
        activePluginIds.insert(pluginId)
    }

    /// 플러그인을 비활성화합니다.
    func deactivate(pluginId: String) {
        activePluginIds.remove(pluginId)
    }

    /// 플러그인이 활성 상태인지 확인합니다.
    func isActive(pluginId: String) -> Bool {
        activePluginIds.contains(pluginId)
    }
}
