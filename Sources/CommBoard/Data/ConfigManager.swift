import Foundation
import Yams

/// CommBoard 앱 설정 구조체
public struct AppConfig: Codable, Equatable {
    public var refreshInterval: TimeInterval
    public var showNotificationBadge: Bool
    public var maxNotificationsPerPlugin: Int

    public init(
        refreshInterval: TimeInterval = 60,
        showNotificationBadge: Bool = true,
        maxNotificationsPerPlugin: Int = 100
    ) {
        self.refreshInterval = refreshInterval
        self.showNotificationBadge = showNotificationBadge
        self.maxNotificationsPerPlugin = maxNotificationsPerPlugin
    }

    public static let `default` = AppConfig()
}

/// 플러그인별 YAML 설정 구조체
public struct PluginConfigFile: Codable, Equatable {
    public var pluginId: String
    public var enabled: Bool
    public var settings: [String: String]

    public init(pluginId: String, enabled: Bool = true, settings: [String: String] = [:]) {
        self.pluginId = pluginId
        self.enabled = enabled
        self.settings = settings
    }
}

/// `~/.commboard/` 하위 YAML 설정 파일을 관리합니다
public final class ConfigManager {

    /// ConfigManager 에러 타입
    public enum ConfigError: Error, Equatable {
        case fileNotFound(path: String)
        case encodingFailed
        case decodingFailed(reason: String)
    }

    private let baseDirectory: URL
    private let fileManager: FileManager

    /// 기본 `~/.commboard/` 경로를 사용하는 ConfigManager
    public convenience init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.init(baseDirectory: home.appendingPathComponent(".commboard"))
    }

    /// 커스텀 baseDirectory를 사용하는 ConfigManager (테스트용)
    public init(baseDirectory: URL, fileManager: FileManager = .default) {
        self.baseDirectory = baseDirectory
        self.fileManager = fileManager
    }

    // MARK: - Directory Paths

    public var configFileURL: URL {
        return baseDirectory.appendingPathComponent("config.yaml")
    }

    public var pluginsDirectoryURL: URL {
        return baseDirectory.appendingPathComponent("plugins")
    }

    // MARK: - Directory Setup

    /// 필요한 디렉토리를 자동 생성합니다
    public func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: pluginsDirectoryURL, withIntermediateDirectories: true)
    }

    // MARK: - App Config

    /// 앱 설정을 로드합니다. 파일이 없으면 기본값을 반환합니다.
    public func loadAppConfig() throws -> AppConfig {
        guard fileManager.fileExists(atPath: configFileURL.path) else {
            return .default
        }
        let data = try Data(contentsOf: configFileURL)
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw ConfigError.decodingFailed(reason: "UTF-8 디코딩 실패")
        }
        do {
            return try YAMLDecoder().decode(AppConfig.self, from: yamlString)
        } catch {
            throw ConfigError.decodingFailed(reason: error.localizedDescription)
        }
    }

    /// 앱 설정을 저장합니다
    public func saveAppConfig(_ config: AppConfig) throws {
        try ensureDirectoriesExist()
        do {
            let yamlString = try YAMLEncoder().encode(config)
            guard let data = yamlString.data(using: .utf8) else {
                throw ConfigError.encodingFailed
            }
            try data.write(to: configFileURL)
        } catch let error as ConfigError {
            throw error
        } catch {
            throw ConfigError.encodingFailed
        }
    }

    // MARK: - Plugin Configs

    /// 특정 플러그인의 설정 파일 URL을 반환합니다
    public func pluginConfigURL(for pluginId: String) -> URL {
        return pluginsDirectoryURL.appendingPathComponent("\(pluginId).yaml")
    }

    /// 특정 플러그인의 설정을 로드합니다
    public func loadPluginConfig(pluginId: String) throws -> PluginConfigFile {
        let url = pluginConfigURL(for: pluginId)
        guard fileManager.fileExists(atPath: url.path) else {
            throw ConfigError.fileNotFound(path: url.path)
        }
        let data = try Data(contentsOf: url)
        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw ConfigError.decodingFailed(reason: "UTF-8 디코딩 실패")
        }
        do {
            return try YAMLDecoder().decode(PluginConfigFile.self, from: yamlString)
        } catch {
            throw ConfigError.decodingFailed(reason: error.localizedDescription)
        }
    }

    /// 특정 플러그인의 설정을 저장합니다
    public func savePluginConfig(_ config: PluginConfigFile) throws {
        try ensureDirectoriesExist()
        let url = pluginConfigURL(for: config.pluginId)
        do {
            let yamlString = try YAMLEncoder().encode(config)
            guard let data = yamlString.data(using: .utf8) else {
                throw ConfigError.encodingFailed
            }
            try data.write(to: url)
        } catch let error as ConfigError {
            throw error
        } catch {
            throw ConfigError.encodingFailed
        }
    }

    /// plugins/ 디렉토리 내 모든 플러그인 설정을 로드합니다
    public func loadAllPluginConfigs() throws -> [PluginConfigFile] {
        guard fileManager.fileExists(atPath: pluginsDirectoryURL.path) else {
            return []
        }
        let contents = try fileManager.contentsOfDirectory(
            at: pluginsDirectoryURL,
            includingPropertiesForKeys: nil
        )
        let yamlFiles = contents.filter { $0.pathExtension == "yaml" }
        return try yamlFiles.compactMap { url -> PluginConfigFile? in
            let data = try Data(contentsOf: url)
            guard let yamlString = String(data: data, encoding: .utf8) else { return nil }
            return try? YAMLDecoder().decode(PluginConfigFile.self, from: yamlString)
        }
    }
}
