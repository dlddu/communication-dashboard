import Foundation
import Yams

/// Errors thrown by ConfigManager operations.
public enum ConfigManagerError: Error, Equatable {
    case fileNotFound(path: String)
    case parseError(reason: String)
    case writeError(reason: String)
}

/// Manages reading and writing YAML configuration files.
public final class ConfigManager {
    public let configDirectory: URL
    public let pluginsDirectory: URL

    public init(configDirectory: URL) {
        self.configDirectory = configDirectory
        self.pluginsDirectory = configDirectory.appendingPathComponent("plugins")
    }

    /// Convenience init using the default ~/.commboard directory.
    public convenience init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.init(configDirectory: home.appendingPathComponent(".commboard"))
    }

    // MARK: - Main Config

    /// Reads and parses the main config.yaml file.
    public func readConfig() throws -> [String: Any] {
        let configURL = configDirectory.appendingPathComponent("config.yaml")
        return try readYAML(at: configURL)
    }

    /// Writes a dictionary to config.yaml as YAML.
    public func writeConfig(_ config: [String: Any]) throws {
        let configURL = configDirectory.appendingPathComponent("config.yaml")
        try writeYAML(config, to: configURL)
    }

    // MARK: - Plugin Configs

    /// Reads all YAML files from the plugins directory.
    public func readPluginConfigs() throws -> [[String: Any]] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: pluginsDirectory.path) else {
            return []
        }

        let contents = try fm.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil
        )

        return try contents
            .filter { $0.pathExtension == "yaml" || $0.pathExtension == "yml" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { try readYAML(at: $0) }
    }

    /// Reads a single plugin config by plugin id.
    public func readPluginConfig(pluginId: String) throws -> [String: Any] {
        let url = pluginsDirectory.appendingPathComponent("\(pluginId).yaml")
        return try readYAML(at: url)
    }

    // MARK: - Helpers

    private func readYAML(at url: URL) throws -> [String: Any] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else {
            throw ConfigManagerError.fileNotFound(path: url.path)
        }

        let contents: String
        do {
            contents = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ConfigManagerError.parseError(reason: error.localizedDescription)
        }

        guard let parsed = try Yams.load(yaml: contents) as? [String: Any] else {
            throw ConfigManagerError.parseError(reason: "Root YAML element is not a mapping")
        }
        return parsed
    }

    private func writeYAML(_ dict: [String: Any], to url: URL) throws {
        let fm = FileManager.default
        let dir = url.deletingLastPathComponent()

        if !fm.fileExists(atPath: dir.path) {
            do {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                throw ConfigManagerError.writeError(reason: error.localizedDescription)
            }
        }

        let yaml: String
        do {
            yaml = try Yams.dump(object: dict)
        } catch {
            throw ConfigManagerError.writeError(reason: error.localizedDescription)
        }

        do {
            try yaml.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            throw ConfigManagerError.writeError(reason: error.localizedDescription)
        }
    }
}
