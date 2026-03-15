import Foundation
import Yams

/// 앱 및 플러그인 설정 파일을 관리합니다. YAML 형식을 사용합니다.
final class ConfigManager {

    // MARK: - Properties

    private let baseDirectory: URL
    private let pluginsDirectory: URL

    // MARK: - Init

    /// 기본 디렉토리를 지정하여 초기화합니다. 디렉토리가 없으면 생성합니다.
    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
        self.pluginsDirectory = baseDirectory.appendingPathComponent("plugins", isDirectory: true)

        // 디렉토리가 없으면 생성
        try? FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - AppConfig

    /// config.yaml을 로드합니다. 파일이 없으면 기본값을 반환합니다.
    func loadConfig() throws -> AppConfig {
        let configURL = baseDirectory.appendingPathComponent("config.yaml")

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return createDefaultConfig()
        }

        let content = try String(contentsOf: configURL, encoding: .utf8)

        // Yams를 사용하여 YAML 파싱 - 파싱 오류는 그대로 throw됩니다
        let decoder = YAMLDecoder()
        return try decoder.decode(AppConfig.self, from: content)
    }

    /// AppConfig를 config.yaml에 저장합니다.
    func saveConfig(_ config: AppConfig) throws {
        let configURL = baseDirectory.appendingPathComponent("config.yaml")
        let encoder = YAMLEncoder()
        let content = try encoder.encode(config)
        try content.write(to: configURL, atomically: true, encoding: .utf8)
    }

    /// 기본 AppConfig를 생성합니다.
    func createDefaultConfig() -> AppConfig {
        AppConfig(refreshInterval: 30, theme: "light", language: "en")
    }

    // MARK: - PluginConfig

    /// 특정 플러그인의 설정을 로드합니다. 파일이 없으면 nil을 반환합니다.
    func loadPluginConfig(pluginId: String) throws -> PluginConfig? {
        let pluginURL = pluginsDirectory.appendingPathComponent("\(pluginId).yaml")

        guard FileManager.default.fileExists(atPath: pluginURL.path) else {
            return nil
        }

        let content = try String(contentsOf: pluginURL, encoding: .utf8)
        let decoder = YAMLDecoder()
        return try decoder.decode(PluginConfig.self, from: content)
    }

    /// 모든 플러그인 설정을 로드합니다.
    func loadAllPluginConfigs() throws -> [PluginConfig] {
        guard FileManager.default.fileExists(atPath: pluginsDirectory.path) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil
        )

        let yamlFiles = contents.filter { $0.pathExtension == "yaml" }
        let decoder = YAMLDecoder()

        return try yamlFiles.compactMap { url in
            let content = try String(contentsOf: url, encoding: .utf8)
            return try? decoder.decode(PluginConfig.self, from: content)
        }
    }

    /// 플러그인 설정을 plugins/{pluginId}.yaml에 저장합니다.
    func savePluginConfig(_ config: PluginConfig) throws {
        // plugins 디렉토리가 없으면 생성
        try FileManager.default.createDirectory(
            at: pluginsDirectory,
            withIntermediateDirectories: true
        )

        let pluginURL = pluginsDirectory.appendingPathComponent("\(config.pluginId).yaml")
        let encoder = YAMLEncoder()
        let content = try encoder.encode(config)
        try content.write(to: pluginURL, atomically: true, encoding: .utf8)
    }
}
