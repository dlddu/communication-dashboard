import XCTest
import GRDB
@testable import CommunicationDashboard

final class DatabaseManagerTests: XCTestCase {
    var databaseManager: DatabaseManager!

    override func setUp() {
        super.setUp()
        // Use in-memory database for test isolation
        databaseManager = DatabaseManager(inMemory: true)
    }

    override func tearDown() {
        databaseManager = nil
        super.tearDown()
    }

    // MARK: - Happy Path Tests

    func testInitializeDatabaseCreatesConnection() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        XCTAssertNotNil(dbQueue, "Database queue should be initialized")
    }

    func testInitializeRunsMigrations() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            // Check that migrations table exists
            let hasMigrationsTable = try db.tableExists("grdb_migrations")
            XCTAssertTrue(hasMigrationsTable, "Migrations table should exist")
        }
    }

    func testInitializeCreatesItemsTable() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let hasItemsTable = try db.tableExists("items")
            XCTAssertTrue(hasItemsTable, "items table should be created")

            // Verify table columns
            let columns = try db.columns(in: "items")
            let columnNames = columns.map { $0.name }

            XCTAssertTrue(columnNames.contains("id"), "items table should have id column")
            XCTAssertTrue(columnNames.contains("title"), "items table should have title column")
            XCTAssertTrue(columnNames.contains("content"), "items table should have content column")
            XCTAssertTrue(columnNames.contains("created_at"), "items table should have created_at column")
            XCTAssertTrue(columnNames.contains("updated_at"), "items table should have updated_at column")
        }
    }

    func testInitializeCreatesEmbeddingsTable() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let hasEmbeddingsTable = try db.tableExists("embeddings")
            XCTAssertTrue(hasEmbeddingsTable, "embeddings table should be created")

            // Verify table columns
            let columns = try db.columns(in: "embeddings")
            let columnNames = columns.map { $0.name }

            XCTAssertTrue(columnNames.contains("id"), "embeddings table should have id column")
            XCTAssertTrue(columnNames.contains("item_id"), "embeddings table should have item_id column")
            XCTAssertTrue(columnNames.contains("embedding"), "embeddings table should have embedding column")
            XCTAssertTrue(columnNames.contains("model_version"), "embeddings table should have model_version column")
            XCTAssertTrue(columnNames.contains("created_at"), "embeddings table should have created_at column")
        }
    }

    func testInitializeCreatesConfigVersionsTable() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let hasConfigTable = try db.tableExists("config_versions")
            XCTAssertTrue(hasConfigTable, "config_versions table should be created")

            // Verify table columns
            let columns = try db.columns(in: "config_versions")
            let columnNames = columns.map { $0.name }

            XCTAssertTrue(columnNames.contains("id"), "config_versions table should have id column")
            XCTAssertTrue(columnNames.contains("key"), "config_versions table should have key column")
            XCTAssertTrue(columnNames.contains("value"), "config_versions table should have value column")
            XCTAssertTrue(columnNames.contains("updated_at"), "config_versions table should have updated_at column")
        }
    }

    func testInitializeCreatesFTSVirtualTable() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let hasFTSTable = try db.tableExists("items_fts")
            XCTAssertTrue(hasFTSTable, "items_fts virtual table should be created")

            // Verify it's an FTS5 table
            let sql = try String.fetchOne(
                db,
                sql: "SELECT sql FROM sqlite_master WHERE type='table' AND name='items_fts'"
            )
            XCTAssertNotNil(sql, "FTS table definition should exist")
            XCTAssertTrue(sql?.contains("fts5") ?? false, "Should be an FTS5 table")
        }
    }

    func testEmbeddingsTableHasForeignKeyToItems() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let foreignKeys = try db.foreignKeys(on: "embeddings")
            let hasItemsForeignKey = foreignKeys.contains { fk in
                fk.destinationTable == "items" && fk.mapping.contains { $0.origin == "item_id" }
            }
            XCTAssertTrue(hasItemsForeignKey, "embeddings table should have foreign key to items table")
        }
    }

    func testConfigVersionsTableHasUniqueConstraintOnKey() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.write { db in
            // Insert first config entry
            try db.execute(
                sql: "INSERT INTO config_versions (key, value, updated_at) VALUES (?, ?, ?)",
                arguments: ["test_key", "value1", Date()]
            )

            // Attempt to insert duplicate key should fail
            XCTAssertThrowsError(
                try db.execute(
                    sql: "INSERT INTO config_versions (key, value, updated_at) VALUES (?, ?, ?)",
                    arguments: ["test_key", "value2", Date()]
                ),
                "Should throw error on duplicate key insertion"
            ) { error in
                let dbError = error as? DatabaseError
                XCTAssertEqual(dbError?.resultCode, .SQLITE_CONSTRAINT, "Should be a constraint violation")
            }
        }
    }

    func testItemsTableHasPrimaryKey() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let primaryKey = try db.primaryKey("items")
            XCTAssertNotNil(primaryKey, "items table should have a primary key")
            XCTAssertEqual(primaryKey.columns, ["id"], "Primary key should be on id column")
        }
    }

    // MARK: - Edge Case Tests

    func testInitializeCanBeCalledMultipleTimes() throws {
        // Act
        try databaseManager.initialize()
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        XCTAssertNotNil(dbQueue, "Database should remain functional after multiple initializations")
    }

    func testDatabaseSupportsTransactions() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act
        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                arguments: ["Test", "Content", Date(), Date()]
            )
        }

        // Assert
        let count = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }
        XCTAssertEqual(count, 1, "Transaction should commit successfully")
    }

    func testDatabaseRollsBackOnError() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act & Assert
        XCTAssertThrowsError(
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                    arguments: ["Test", "Content", Date(), Date()]
                )
                // Force error with invalid SQL
                try db.execute(sql: "INVALID SQL")
            }
        )

        // Verify rollback
        let count = try dbQueue.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
        }
        XCTAssertEqual(count, 0, "Transaction should be rolled back on error")
    }

    func testFTSTableCanBeQueried() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO items (id, title, content, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
                arguments: [1, "Test Title", "Test Content", Date(), Date()]
            )
            try db.execute(
                sql: "INSERT INTO items_fts (rowid, title, content) VALUES (?, ?, ?)",
                arguments: [1, "Test Title", "Test Content"]
            )
        }

        // Act
        let results = try dbQueue.read { db in
            try Row.fetchAll(db, sql: "SELECT * FROM items_fts WHERE items_fts MATCH 'test'")
        }

        // Assert
        XCTAssertGreaterThan(results.count, 0, "FTS search should return results")
    }

    // MARK: - Error Case Tests

    func testGetDatabaseQueueThrowsWhenNotInitialized() {
        // Arrange
        let uninitializedManager = DatabaseManager(inMemory: true)

        // Act & Assert
        XCTAssertThrowsError(
            try uninitializedManager.getDatabaseQueue(),
            "Should throw error when accessing database before initialization"
        ) { error in
            XCTAssertTrue(
                error is DatabaseManager.DatabaseError,
                "Should throw DatabaseError"
            )
        }
    }

    func testInsertIntoItemsFailsWithInvalidData() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act & Assert - Missing required fields
        XCTAssertThrowsError(
            try dbQueue.write { db in
                try db.execute(sql: "INSERT INTO items (title) VALUES (?)", arguments: ["Test"])
            },
            "Should throw error when required fields are missing"
        )
    }

    func testEmbeddingsCannotBeInsertedWithInvalidItemId() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        // Act & Assert - Foreign key constraint violation
        XCTAssertThrowsError(
            try dbQueue.write { db in
                try db.execute(
                    sql: "INSERT INTO embeddings (item_id, embedding, model_version, created_at) VALUES (?, ?, ?, ?)",
                    arguments: [999, Data(), "v1", Date()]
                )
            },
            "Should throw error on foreign key constraint violation"
        ) { error in
            let dbError = error as? DatabaseError
            XCTAssertEqual(dbError?.resultCode, .SQLITE_CONSTRAINT, "Should be a constraint violation")
        }
    }

    func testDatabaseMigrationVersionIsTracked() throws {
        // Act
        try databaseManager.initialize()

        // Assert
        let dbQueue = try databaseManager.getDatabaseQueue()
        try dbQueue.read { db in
            let migrations = try Row.fetchAll(db, sql: "SELECT * FROM grdb_migrations")
            XCTAssertGreaterThan(migrations.count, 0, "Should have recorded migration history")
        }
    }

    func testConcurrentReadsAreSupported() throws {
        // Arrange
        try databaseManager.initialize()
        let dbQueue = try databaseManager.getDatabaseQueue()

        try dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO items (title, content, created_at, updated_at) VALUES (?, ?, ?, ?)",
                arguments: ["Test", "Content", Date(), Date()]
            )
        }

        // Act - Perform concurrent reads
        let expectation1 = expectation(description: "Read 1")
        let expectation2 = expectation(description: "Read 2")

        DispatchQueue.global().async {
            do {
                _ = try dbQueue.read { db in
                    try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
                }
                expectation1.fulfill()
            } catch {
                XCTFail("Read 1 failed: \(error)")
            }
        }

        DispatchQueue.global().async {
            do {
                _ = try dbQueue.read { db in
                    try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM items")
                }
                expectation2.fulfill()
            } catch {
                XCTFail("Read 2 failed: \(error)")
            }
        }

        // Assert
        wait(for: [expectation1, expectation2], timeout: 5.0)
    }
}
