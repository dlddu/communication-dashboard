import Foundation

/// Service responsible for managing configuration directories
public class ConfigService {
    public enum ConfigError: Error {
        case notInitialized
        case invalidPath
        case initializationFailed(Error)
        case permissionDenied(path: String)
        case creationFailed(path: String, underlying: Error)
    }

    public enum SubdirectoryType: String, CaseIterable {
        case db
        case models
        case cache
        case logs
    }

    static let basePath = ".config/commdash"

    private let baseDirectory: URL
    private var isInitialized: Bool = false
    private var baseDirURL: URL?

    public init(baseDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.baseDirectory = baseDirectory
    }

    public func initialize() throws {
        let configDir = baseDirectory.appendingPathComponent(ConfigService.basePath)

        do {
            // Create base directory
            try FileManager.default.createDirectory(
                at: configDir,
                withIntermediateDirectories: true,
                attributes: nil
            )

            // Create all subdirectories
            for subdirectory in SubdirectoryType.allCases {
                let subdirPath = configDir.appendingPathComponent(subdirectory.rawValue)
                try FileManager.default.createDirectory(
                    at: subdirPath,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }

            baseDirURL = configDir
            isInitialized = true
        } catch let error as CocoaError where error.code == .fileWriteNoPermission || error.code == .fileWriteVolumeReadOnly {
            throw ConfigError.permissionDenied(path: configDir.path)
        } catch {
            throw ConfigError.creationFailed(path: configDir.path, underlying: error)
        }
    }

    public func getDirectoryPath(for type: SubdirectoryType) throws -> URL {
        guard isInitialized, let baseDir = baseDirURL else {
            throw ConfigError.notInitialized
        }

        return baseDir.appendingPathComponent(type.rawValue)
    }

    public func directoryExists() -> Bool {
        guard let baseDir = baseDirURL else {
            let configDir = baseDirectory.appendingPathComponent(ConfigService.basePath)
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: configDir.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }

        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: baseDir.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
}
