import Foundation
import Yams

/// `~/.commboard/config.yaml` 및 `~/.commboard/plugins/*.yaml` 파일을 관리합니다.
public final class ConfigManager {

    public enum Defaults {
        public static let version = "1.0"
        public static let refreshInterval = 300
        public static let theme = "system"
        public static let notificationsEnabled = true
        public static let maxNotificationCount = 100
    }

    public let baseDirectory: URL
    public let pluginsDirectory: URL
    public let configFileURL: URL

    private let fileManager: FileManager

    public init(
        baseDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        if let baseDir = baseDirectory {
            self.baseDirectory = baseDir
        } else {
            let home = fileManager.homeDirectoryForCurrentUser
            self.baseDirectory = home.appendingPathComponent(".commboard")
        }

        self.pluginsDirectory = self.baseDirectory.appendingPathComponent("plugins")
        self.configFileURL = self.baseDirectory.appendingPathComponent("config.yaml")
    }

    // MARK: - Directory Setup

    /// 필요한 디렉토리 구조를 생성합니다.
    public func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(
            at: pluginsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    // MARK: - Main Config

    /// 메인 설정 파일을 로드합니다.
    /// - Returns: 설정 딕셔너리. 파일이 없으면 기본값 반환.
    public func loadConfig() throws -> [String: Any] {
        guard fileManager.fileExists(atPath: configFileURL.path) else {
            return defaultConfig()
        }

        let content = try String(contentsOf: configFileURL, encoding: .utf8)
        guard let decoded = try Yams.load(yaml: content) as? [String: Any] else {
            return defaultConfig()
        }
        return decoded
    }

    /// 메인 설정 파일을 저장합니다.
    /// - Parameter config: 저장할 설정 딕셔너리
    public func saveConfig(_ config: [String: Any]) throws {
        try ensureDirectoriesExist()
        let yaml = try Yams.dump(object: config)
        try yaml.write(to: configFileURL, atomically: true, encoding: .utf8)
    }

    /// 기본 설정을 생성하고 저장합니다. 파일이 이미 존재하면 덮어쓰지 않습니다.
    public func createDefaultConfigIfNeeded() throws {
        guard !fileManager.fileExists(atPath: configFileURL.path) else { return }
        try saveConfig(defaultConfig())
    }

    // MARK: - Plugin Configs

    /// 플러그인 설정 파일을 로드합니다.
    /// - Parameter pluginId: 플러그인 id
    /// - Returns: 플러그인 설정 딕셔너리. 파일이 없으면 빈 딕셔너리 반환.
    public func loadPluginConfig(pluginId: String) throws -> [String: Any] {
        let url = pluginConfigURL(for: pluginId)
        guard fileManager.fileExists(atPath: url.path) else {
            return [:]
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        guard let decoded = try Yams.load(yaml: content) as? [String: Any] else {
            return [:]
        }
        return decoded
    }

    /// 플러그인 설정 파일을 저장합니다.
    /// - Parameters:
    ///   - config: 저장할 설정 딕셔너리
    ///   - pluginId: 플러그인 id
    public func savePluginConfig(_ config: [String: Any], pluginId: String) throws {
        try ensureDirectoriesExist()
        let url = pluginConfigURL(for: pluginId)
        let yaml = try Yams.dump(object: config)
        try yaml.write(to: url, atomically: true, encoding: .utf8)
    }

    /// 모든 플러그인 설정을 로드합니다.
    /// - Returns: pluginId를 키로 하는 설정 딕셔너리 맵
    public func loadAllPluginConfigs() throws -> [String: [String: Any]] {
        guard fileManager.fileExists(atPath: pluginsDirectory.path) else {
            return [:]
        }

        let contents = try fileManager.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil
        )

        var result: [String: [String: Any]] = [:]
        for url in contents where url.pathExtension == "yaml" {
            let pluginId = url.deletingPathExtension().lastPathComponent
            do {
                result[pluginId] = try loadPluginConfig(pluginId: pluginId)
            } catch {
                // 개별 플러그인 로드 실패 시 건너뛰고 나머지 계속 로드
                continue
            }
        }
        return result
    }

    // MARK: - Private Helpers

    private func pluginConfigURL(for pluginId: String) -> URL {
        return pluginsDirectory.appendingPathComponent("\(pluginId).yaml")
    }

    private func defaultConfig() -> [String: Any] {
        return [
            "version": Defaults.version,
            "refresh_interval": Defaults.refreshInterval,
            "theme": Defaults.theme,
            "notifications": [
                "enabled": Defaults.notificationsEnabled,
                "max_count": Defaults.maxNotificationCount
            ]
        ]
    }
}
