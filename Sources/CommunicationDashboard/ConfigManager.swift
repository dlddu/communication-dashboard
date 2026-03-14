import Foundation
import Yams

// MARK: - Config Models

public struct AppConfig: Codable, Equatable {
    public var refreshInterval: Int
    public var theme: String
    public var plugins: [String]

    public init(refreshInterval: Int = 60, theme: String = "system", plugins: [String] = []) {
        self.refreshInterval = refreshInterval
        self.theme = theme
        self.plugins = plugins
    }
}

public struct PluginConfig: Codable, Equatable {
    public var id: String
    public var name: String
    public var enabled: Bool
    public var interval: Int
    public var settings: [String: String]

    public init(
        id: String,
        name: String,
        enabled: Bool = true,
        interval: Int = 300,
        settings: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.enabled = enabled
        self.interval = interval
        self.settings = settings
    }
}

// MARK: - ConfigManagerError

public enum ConfigManagerError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidYAML(String)
    case writeFailure(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Config file not found: \(path)"
        case .invalidYAML(let message):
            return "Invalid YAML: \(message)"
        case .writeFailure(let message):
            return "Write failure: \(message)"
        }
    }
}

// MARK: - ConfigManager

public class ConfigManager {
    private let baseDirectory: URL
    private let fileManager: FileManager

    public var configFileURL: URL {
        baseDirectory.appendingPathComponent("config.yaml")
    }

    public var pluginsDirectory: URL {
        baseDirectory.appendingPathComponent("plugins")
    }

    public init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        if let dir = baseDirectory {
            self.baseDirectory = dir
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser
            self.baseDirectory = home.appendingPathComponent(".commboard")
        }
        self.fileManager = fileManager
    }

    public func loadAppConfig() throws -> AppConfig {
        if !fileManager.fileExists(atPath: configFileURL.path) {
            let defaultConfig = AppConfig()
            try saveAppConfig(defaultConfig)
            return defaultConfig
        }

        let content = try String(contentsOf: configFileURL, encoding: .utf8)
        guard let config = try Yams.load(yaml: content) as? [String: Any] else {
            throw ConfigManagerError.invalidYAML("Root element must be a dictionary")
        }

        let refreshInterval = config["refresh_interval"] as? Int ?? 60
        let theme = config["theme"] as? String ?? "system"

        // Yams may parse YAML sequences as [Any], so convert manually
        var plugins: [String] = []
        if let directPlugins = config["plugins"] as? [String] {
            plugins = directPlugins
        } else if let anyPlugins = config["plugins"] as? [Any] {
            plugins = anyPlugins.compactMap { $0 as? String }
        }

        return AppConfig(refreshInterval: refreshInterval, theme: theme, plugins: plugins)
    }

    public func saveAppConfig(_ config: AppConfig) throws {
        try ensureBaseDirectoryExists()

        let dict: [String: Any] = [
            "refresh_interval": config.refreshInterval,
            "theme": config.theme,
            "plugins": config.plugins
        ]

        let yaml = try Yams.dump(object: dict)
        try yaml.write(to: configFileURL, atomically: true, encoding: .utf8)
    }

    public func loadPluginConfig(pluginId: String) throws -> PluginConfig {
        let pluginFileURL = pluginsDirectory.appendingPathComponent("\(pluginId).yaml")

        if !fileManager.fileExists(atPath: pluginFileURL.path) {
            throw ConfigManagerError.fileNotFound(pluginFileURL.path)
        }

        let content = try String(contentsOf: pluginFileURL, encoding: .utf8)
        guard let dict = try Yams.load(yaml: content) as? [String: Any] else {
            throw ConfigManagerError.invalidYAML("Root element must be a dictionary")
        }

        let id = dict["id"] as? String ?? pluginId
        let name = dict["name"] as? String ?? pluginId
        let enabled = dict["enabled"] as? Bool ?? true
        let interval = dict["interval"] as? Int ?? 300

        // Yams parses YAML mappings as [String: Any], so we need to convert manually
        var settings: [String: String] = [:]
        if let rawSettings = dict["settings"] as? [String: Any] {
            for (key, value) in rawSettings {
                settings[key] = "\(value)"
            }
        } else if let directSettings = dict["settings"] as? [String: String] {
            settings = directSettings
        }

        return PluginConfig(id: id, name: name, enabled: enabled, interval: interval, settings: settings)
    }

    public func savePluginConfig(_ config: PluginConfig) throws {
        try ensurePluginsDirectoryExists()

        let pluginFileURL = pluginsDirectory.appendingPathComponent("\(config.id).yaml")
        let dict: [String: Any] = [
            "id": config.id,
            "name": config.name,
            "enabled": config.enabled,
            "interval": config.interval,
            "settings": config.settings
        ]

        let yaml = try Yams.dump(object: dict)
        try yaml.write(to: pluginFileURL, atomically: true, encoding: .utf8)
    }

    public func loadAllPluginConfigs() throws -> [PluginConfig] {
        guard fileManager.fileExists(atPath: pluginsDirectory.path) else {
            return []
        }

        let files = try fileManager.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "yaml" }

        return try files.compactMap { url in
            let pluginId = url.deletingPathExtension().lastPathComponent
            return try? loadPluginConfig(pluginId: pluginId)
        }
    }

    private func ensureBaseDirectoryExists() throws {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }

    private func ensurePluginsDirectoryExists() throws {
        try ensureBaseDirectoryExists()
        if !fileManager.fileExists(atPath: pluginsDirectory.path) {
            try fileManager.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)
        }
    }
}
