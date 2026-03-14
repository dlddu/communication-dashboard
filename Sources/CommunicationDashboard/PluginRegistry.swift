import Foundation

// MARK: - PluginRegistryError

public enum PluginRegistryError: Error, LocalizedError, Equatable {
    case alreadyRegistered(String)
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered(let id):
            return "Plugin already registered: \(id)"
        case .notFound(let id):
            return "Plugin not found: \(id)"
        }
    }
}

// MARK: - PluginEntry

private struct PluginEntry {
    let plugin: any PluginProtocol
    var isEnabled: Bool
}

// MARK: - PluginRegistry

public class PluginRegistry {
    private var entries: [String: PluginEntry] = [:]

    public init() {}

    /// 플러그인을 레지스트리에 등록합니다.
    /// - Throws: `PluginRegistryError.alreadyRegistered` 동일한 id가 이미 등록되어 있으면 오류를 던집니다.
    public func register(_ plugin: any PluginProtocol) throws {
        guard entries[plugin.id] == nil else {
            throw PluginRegistryError.alreadyRegistered(plugin.id)
        }
        entries[plugin.id] = PluginEntry(plugin: plugin, isEnabled: true)
    }

    /// id로 플러그인을 조회합니다. 존재하지 않으면 nil을 반환합니다.
    public func get(id: String) -> (any PluginProtocol)? {
        entries[id]?.plugin
    }

    /// 등록된 모든 플러그인 목록을 반환합니다.
    public func listAll() -> [any PluginProtocol] {
        entries.values.map { $0.plugin }
    }

    /// 활성화된 플러그인 목록을 반환합니다.
    public func listEnabled() -> [any PluginProtocol] {
        entries.values.filter { $0.isEnabled }.map { $0.plugin }
    }

    /// 플러그인의 활성화 상태를 반환합니다.
    public func isEnabled(id: String) -> Bool? {
        entries[id]?.isEnabled
    }

    /// 플러그인을 활성화합니다.
    /// - Throws: `PluginRegistryError.notFound` 플러그인이 등록되어 있지 않으면 오류를 던집니다.
    public func enable(id: String) throws {
        guard entries[id] != nil else {
            throw PluginRegistryError.notFound(id)
        }
        entries[id]?.isEnabled = true
    }

    /// 플러그인을 비활성화합니다.
    /// - Throws: `PluginRegistryError.notFound` 플러그인이 등록되어 있지 않으면 오류를 던집니다.
    public func disable(id: String) throws {
        guard entries[id] != nil else {
            throw PluginRegistryError.notFound(id)
        }
        entries[id]?.isEnabled = false
    }

    /// 등록된 플러그인 수를 반환합니다.
    public var count: Int {
        entries.count
    }
}
