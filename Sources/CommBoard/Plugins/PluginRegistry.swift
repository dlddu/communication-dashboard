import Foundation

/// 플러그인의 등록, 조회, 활성화 상태 관리를 담당합니다.
public final class PluginRegistry {
    private var plugins: [String: any PluginProtocol] = [:]

    public init() {}

    // MARK: - Registration

    /// 플러그인을 레지스트리에 등록합니다.
    /// 동일한 id가 이미 등록된 경우 덮어씁니다.
    /// - Parameter plugin: 등록할 플러그인
    public func register(plugin: any PluginProtocol) {
        plugins[plugin.id] = plugin
    }

    // MARK: - Lookup

    /// id로 플러그인을 조회합니다.
    /// - Parameter id: 조회할 플러그인 id
    /// - Returns: 등록된 플러그인, 없으면 nil
    public func plugin(id: String) -> (any PluginProtocol)? {
        return plugins[id]
    }

    /// 등록된 모든 플러그인을 반환합니다.
    public var allPlugins: [any PluginProtocol] {
        return Array(plugins.values)
    }

    // MARK: - Filtering

    /// 활성화된 플러그인 목록을 반환합니다.
    public var enabledPlugins: [any PluginProtocol] {
        return plugins.values.filter { $0.isEnabled }
    }

    /// 비활성화된 플러그인 목록을 반환합니다.
    public var disabledPlugins: [any PluginProtocol] {
        return plugins.values.filter { !$0.isEnabled }
    }

    // MARK: - Activation

    /// 플러그인의 활성화 상태를 변경합니다.
    /// - Parameters:
    ///   - id: 대상 플러그인 id
    ///   - enabled: 활성화 여부
    /// - Returns: 변경 성공 여부 (플러그인이 없으면 false)
    @discardableResult
    public func setEnabled(_ enabled: Bool, forPluginId id: String) -> Bool {
        guard let plugin = plugins[id] else { return false }
        plugin.isEnabled = enabled
        return true
    }

    /// 등록된 플러그인 수를 반환합니다.
    public var count: Int {
        return plugins.count
    }

    /// 레지스트리를 초기화합니다.
    public func removeAll() {
        plugins.removeAll()
    }
}
