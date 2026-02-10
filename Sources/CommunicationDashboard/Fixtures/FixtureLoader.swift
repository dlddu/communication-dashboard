import Foundation
import Yams

/// Loads fixture data from JSON and YAML files
class FixtureLoader {
    private let fixturesDirectory: String

    init(fixturesDirectory: String) {
        self.fixturesDirectory = fixturesDirectory
    }

    /// Load and decode a JSON fixture file
    func loadJSON<T: Decodable>(filename: String) throws -> T {
        let path = (fixturesDirectory as NSString).appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: path) else {
            throw FixtureLoaderError.fileNotFound(filename)
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            throw FixtureLoaderError.fileReadError(filename)
        }

        guard !data.isEmpty else {
            throw FixtureLoaderError.emptyFile(filename)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FixtureLoaderError.decodingError(filename, error)
        }
    }

    /// Load and decode a YAML fixture file
    func loadYAML<T: Decodable>(filename: String) throws -> T {
        let path = (fixturesDirectory as NSString).appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: path) else {
            throw FixtureLoaderError.fileNotFound(filename)
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            throw FixtureLoaderError.fileReadError(filename)
        }

        guard !data.isEmpty else {
            throw FixtureLoaderError.emptyFile(filename)
        }

        guard let yamlString = String(data: data, encoding: .utf8) else {
            throw FixtureLoaderError.fileReadError(filename)
        }

        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(T.self, from: yamlString)
        } catch {
            throw FixtureLoaderError.decodingError(filename, error)
        }
    }

    /// Load raw file contents as string
    func loadRaw(filename: String) throws -> String {
        let path = (fixturesDirectory as NSString).appendingPathComponent(filename)

        guard FileManager.default.fileExists(atPath: path) else {
            throw FixtureLoaderError.fileNotFound(filename)
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            throw FixtureLoaderError.fileReadError(filename)
        }

        guard let content = String(data: data, encoding: .utf8) else {
            throw FixtureLoaderError.fileReadError(filename)
        }

        return content
    }
}
