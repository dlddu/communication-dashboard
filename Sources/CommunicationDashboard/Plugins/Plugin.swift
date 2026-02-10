import Foundation

/// Protocol for all communication plugins
protocol Plugin {
    var name: String { get }
    func fetch() async throws -> [Any]
}
