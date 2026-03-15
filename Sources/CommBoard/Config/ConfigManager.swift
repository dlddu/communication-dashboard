// ConfigManager - ~/.commboard/config.yaml and ~/.commboard/plugins/*.yaml read/write

import Foundation
import Yams

// MARK: - Config models

struct AppConfig: Codable, Equatable {
    var refreshInterval: Int
    var theme: String
    var enableNotifications: Bool

    enum CodingKeys: String, CodingKey {
        case refreshInterval = "refresh_interval"
        case theme
        case enableNotifications = "enable_notifications"
    }
}

struct PluginConfig: Codable, Equatable {
    var id: String
    var name: String
    var enabled: Bool
    var settings: [String: String]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case enabled
        case settings
    }
}

// MARK: - ConfigManager

class ConfigManager {
    let baseDirectory: URL

    init(baseDirectory: URL) {
        self.baseDirectory = baseDirectory
    }

    func loadAppConfig() throws -> AppConfig {
        let configURL = baseDirectory.appendingPathComponent("config.yaml")

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            // Return default config when file does not exist
            return AppConfig(
                refreshInterval: 30,
                theme: "system",
                enableNotifications: true
            )
        }

        let yamlString = try String(contentsOf: configURL, encoding: .utf8)
        return try YAMLDecoder().decode(AppConfig.self, from: yamlString)
    }

    func saveAppConfig(_ config: AppConfig) throws {
        let configURL = baseDirectory.appendingPathComponent("config.yaml")

        // Create intermediate directories if needed
        try FileManager.default.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let yamlString = try YAMLEncoder().encode(config)
        try yamlString.write(to: configURL, atomically: true, encoding: .utf8)
    }

    func loadPluginConfig(pluginId: String) throws -> PluginConfig {
        let pluginsDir = baseDirectory.appendingPathComponent("plugins")
        let pluginURL = pluginsDir.appendingPathComponent("\(pluginId).yaml")

        guard FileManager.default.fileExists(atPath: pluginURL.path) else {
            throw ConfigManagerError.pluginConfigNotFound(pluginId)
        }

        let yamlString = try String(contentsOf: pluginURL, encoding: .utf8)
        return try YAMLDecoder().decode(PluginConfig.self, from: yamlString)
    }

    func savePluginConfig(_ config: PluginConfig) throws {
        let pluginsDir = baseDirectory.appendingPathComponent("plugins")

        // Create intermediate directories if needed
        try FileManager.default.createDirectory(
            at: pluginsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let pluginURL = pluginsDir.appendingPathComponent("\(config.id).yaml")
        let yamlString = try YAMLEncoder().encode(config)
        try yamlString.write(to: pluginURL, atomically: true, encoding: .utf8)
    }

    func loadAllPluginConfigs() throws -> [PluginConfig] {
        let pluginsDir = baseDirectory.appendingPathComponent("plugins")

        guard FileManager.default.fileExists(atPath: pluginsDir.path) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(
            at: pluginsDir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )

        let yamlFiles = contents.filter { $0.pathExtension == "yaml" }

        return try yamlFiles.compactMap { url in
            let yamlString = try String(contentsOf: url, encoding: .utf8)
            return try? YAMLDecoder().decode(PluginConfig.self, from: yamlString)
        }
    }
}

// MARK: - ConfigManagerError

enum ConfigManagerError: Error {
    case pluginConfigNotFound(String)
}
