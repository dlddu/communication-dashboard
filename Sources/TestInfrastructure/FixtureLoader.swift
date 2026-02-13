import Foundation
import Yams

/// Loader for test fixture files
public class FixtureLoader {
    public enum FixtureError: Error {
        case fileNotFound(String)
        case invalidPath(String)
        case loadFailed(String)
    }

    public enum ParseError: Error {
        case jsonParsingFailed(Error)
        case yamlParsingFailed(Error)
        case decodingFailed(Error)
    }

    public enum EncodingError: Error {
        case invalidEncoding(String)
    }

    private var cache: [String: Data] = [:]
    private let fixturesDirectory: URL

    public init() {
        // Resolve the fixtures directory from the bundle
        if let resourcePath = Bundle.module.resourcePath {
            self.fixturesDirectory = URL(fileURLWithPath: resourcePath)
                .appendingPathComponent("Fixtures")
        } else {
            // Fallback for development
            self.fixturesDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Tests/Fixtures")
        }
    }

    /// Load fixture data from file
    public func loadFixture(path: String) throws -> Data {
        // Validate path (prevent path traversal)
        guard !path.isEmpty else {
            throw FixtureError.invalidPath("Path cannot be empty")
        }

        guard !path.contains("..") else {
            throw FixtureError.invalidPath("Path traversal not allowed")
        }

        // Check cache first
        if let cached = cache[path] {
            return cached
        }

        // Resolve file path
        let fileURL = fixturesDirectory.appendingPathComponent(path)

        // Load file
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw FixtureError.fileNotFound("Fixture not found: \(path)")
        }

        do {
            let data = try Data(contentsOf: fileURL)
            cache[path] = data
            return data
        } catch {
            throw FixtureError.loadFailed("Failed to load fixture: \(error.localizedDescription)")
        }
    }

    /// Load fixture as string
    public func loadFixtureAsString(path: String) throws -> String {
        let data = try loadFixture(path: path)

        guard let string = String(data: data, encoding: .utf8) else {
            throw EncodingError.invalidEncoding("Failed to decode fixture as UTF-8 string")
        }

        return string
    }

    /// Load and parse JSON fixture
    public func loadAndParse<T: Decodable>(path: String) throws -> T {
        let data = try loadFixture(path: path)

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ParseError.jsonParsingFailed(error)
        }
    }

    /// Load and parse YAML fixture
    public func loadYAMLAndParse<T: Decodable>(path: String) throws -> T {
        let data = try loadFixture(path: path)

        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ParseError.yamlParsingFailed(error)
        }
    }

    /// Resolve full path to fixture
    public func resolveFixturePath(_ path: String) throws -> String {
        let fileURL = fixturesDirectory.appendingPathComponent(path)
        return fileURL.path
    }

    /// List all fixtures in a directory
    public func listFixtures(in directory: String) throws -> [String] {
        let directoryURL = fixturesDirectory.appendingPathComponent(directory)

        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            throw FixtureError.fileNotFound("Directory not found: \(directory)")
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil
            )
            return contents.map { $0.lastPathComponent }
        } catch {
            throw FixtureError.loadFailed("Failed to list directory: \(error.localizedDescription)")
        }
    }

    /// Check if fixture exists
    public func fixtureExists(path: String) -> Bool {
        let fileURL = fixturesDirectory.appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Get fixture URL
    public func getFixtureURL(path: String) throws -> URL {
        let fileURL = fixturesDirectory.appendingPathComponent(path)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw FixtureError.fileNotFound("Fixture not found: \(path)")
        }

        return fileURL
    }

    /// Load all fixtures in a directory
    public func loadAllFixtures(in directory: String) throws -> [String: Data] {
        let files = try listFixtures(in: directory)
        var fixtures: [String: Data] = [:]

        for file in files {
            let fullPath = "\(directory)/\(file)"
            if let data = try? loadFixture(path: fullPath) {
                fixtures[file] = data
            }
        }

        return fixtures
    }

    /// Clear cache
    public func clearCache() {
        cache.removeAll()
    }
}
