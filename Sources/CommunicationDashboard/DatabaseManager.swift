import Foundation
import GRDB

/// Manager responsible for database initialization and migrations
public class DatabaseManager {
    enum DatabaseError: Error {
        case notInitialized
        case initializationFailed(Error)
        case migrationFailed(Error)
    }

    private var dbQueue: DatabaseQueue?
    private let inMemory: Bool

    public init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }

    public func initialize() throws {
        do {
            // Create database queue
            if inMemory {
                dbQueue = try DatabaseQueue()
            } else {
                // For file-based database (not used in tests yet)
                fatalError("File-based database not implemented yet")
            }

            // Run migrations
            var migrator = DatabaseMigrator()
            try setupMigrations(&migrator)

            if let queue = dbQueue {
                try migrator.migrate(queue)
            }
        } catch {
            throw DatabaseError.initializationFailed(error)
        }
    }

    public func getDatabaseQueue() throws -> DatabaseQueue {
        guard let queue = dbQueue else {
            throw DatabaseError.notInitialized
        }
        return queue
    }

    private func setupMigrations(_ migrator: inout DatabaseMigrator) throws {
        // Migration v1: Create initial schema
        migrator.registerMigration("v1_initial_schema") { db in
            // Create items table
            try db.create(table: "items") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("content", .text).notNull()
                t.column("created_at", .datetime).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            // Create embeddings table with foreign key
            try db.create(table: "embeddings") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("item_id", .integer).notNull()
                    .references("items", onDelete: .cascade)
                t.column("embedding", .blob).notNull()
                t.column("model_version", .text).notNull()
                t.column("created_at", .datetime).notNull()
            }

            // Create config_versions table with unique constraint
            try db.create(table: "config_versions") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("key", .text).notNull().unique()
                t.column("value", .text).notNull()
                t.column("updated_at", .datetime).notNull()
            }

            // Create FTS5 virtual table
            try db.create(virtualTable: "items_fts", using: FTS5()) { t in
                t.column("title")
                t.column("content")
            }
        }
    }
}
