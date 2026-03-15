import XCTest
@testable import CommBoard

// MARK: - Test Double

/// Minimal concrete implementation of PluginProtocol for use in tests.
final class MockPlugin: PluginProtocol {
    let id: String
    let name: String
    let icon: String
    let config: [String: Any]

    var fetchResult: Result<[Notification], Error> = .success([])
    var connectionResult: Result<Bool, Error> = .success(true)

    init(
        id: String,
        name: String = "Mock Plugin",
        icon: String = "star",
        config: [String: Any] = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.config = config
    }

    func fetch() async throws -> [Notification] {
        try fetchResult.get()
    }

    func testConnection() async throws -> Bool {
        try connectionResult.get()
    }
}

// MARK: - Tests

final class PluginRegistryTests: XCTestCase {

    // MARK: - Properties

    private var sut: PluginRegistry!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = PluginRegistry()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Registration: happy path

    func test_register_single_plugin_succeeds() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")

        // Act & Assert
        XCTAssertNoThrow(try sut.register(plugin))
    }

    func test_register_multiple_plugins_with_different_ids_succeeds() throws {
        // Arrange
        let plugins = ["slack", "github", "jira"].map { MockPlugin(id: $0) }

        // Act & Assert
        for p in plugins { XCTAssertNoThrow(try sut.register(p)) }
    }

    // MARK: - Registration: error cases

    func test_register_duplicate_plugin_id_throws_duplicatePlugin_error() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack")
        try sut.register(plugin)

        // Act & Assert
        XCTAssertThrowsError(try sut.register(MockPlugin(id: "slack"))) { error in
            XCTAssertEqual(
                error as? PluginRegistryError,
                PluginRegistryError.duplicatePlugin(id: "slack")
            )
        }
    }

    // MARK: - Lookup: getPlugin

    func test_getPlugin_returns_nil_when_no_plugin_registered() {
        // Act
        let result = sut.getPlugin(id: "unknown")

        // Assert
        XCTAssertNil(result)
    }

    func test_getPlugin_returns_plugin_by_id_after_registration() throws {
        // Arrange
        let plugin = MockPlugin(id: "github", name: "GitHub")
        try sut.register(plugin)

        // Act
        let result = sut.getPlugin(id: "github")

        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, "github")
        XCTAssertEqual(result?.name, "GitHub")
    }

    func test_getPlugin_returns_correct_plugin_among_multiple() throws {
        // Arrange
        let plugins = ["slack", "github", "jira"].map { MockPlugin(id: $0) }
        for p in plugins { try sut.register(p) }

        // Act
        let result = sut.getPlugin(id: "jira")

        // Assert
        XCTAssertEqual(result?.id, "jira")
    }

    // MARK: - Lookup: getAllPlugins

    func test_getAllPlugins_returns_empty_array_when_no_plugins_registered() {
        // Act
        let results = sut.getAllPlugins()

        // Assert
        XCTAssertTrue(results.isEmpty)
    }

    func test_getAllPlugins_returns_all_registered_plugins() throws {
        // Arrange
        let ids = ["slack", "github", "jira"]
        for id in ids { try sut.register(MockPlugin(id: id)) }

        // Act
        let results = sut.getAllPlugins()
        let resultIds = results.map { $0.id }.sorted()

        // Assert
        XCTAssertEqual(resultIds, ids.sorted())
    }

    // MARK: - Activation: happy path

    func test_activate_plugin_marks_it_as_active() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))

        // Act
        try sut.activate(id: "slack")

        // Assert
        XCTAssertTrue(sut.isActive(id: "slack"))
    }

    func test_deactivate_plugin_marks_it_as_inactive() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))
        try sut.activate(id: "slack")

        // Act
        try sut.deactivate(id: "slack")

        // Assert
        XCTAssertFalse(sut.isActive(id: "slack"))
    }

    func test_plugin_is_inactive_by_default_after_registration() throws {
        // Arrange
        try sut.register(MockPlugin(id: "github"))

        // Assert
        XCTAssertFalse(sut.isActive(id: "github"))
    }

    func test_activate_multiple_plugins_all_become_active() throws {
        // Arrange
        let ids = ["slack", "github", "jira"]
        for id in ids { try sut.register(MockPlugin(id: id)) }

        // Act
        for id in ids { try sut.activate(id: id) }

        // Assert
        for id in ids { XCTAssertTrue(sut.isActive(id: id)) }
    }

    func test_deactivate_only_affects_targeted_plugin() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))
        try sut.register(MockPlugin(id: "github"))
        try sut.activate(id: "slack")
        try sut.activate(id: "github")

        // Act
        try sut.deactivate(id: "slack")

        // Assert
        XCTAssertFalse(sut.isActive(id: "slack"))
        XCTAssertTrue(sut.isActive(id: "github"))
    }

    // MARK: - Activation: edge cases

    func test_isActive_returns_false_for_unknown_plugin_id() {
        // Act & Assert
        XCTAssertFalse(sut.isActive(id: "unknown"))
    }

    func test_activate_unregistered_plugin_throws_pluginNotFound_error() {
        // Act & Assert
        XCTAssertThrowsError(try sut.activate(id: "ghost")) { error in
            XCTAssertEqual(
                error as? PluginRegistryError,
                PluginRegistryError.pluginNotFound(id: "ghost")
            )
        }
    }

    func test_deactivate_unregistered_plugin_throws_pluginNotFound_error() {
        // Act & Assert
        XCTAssertThrowsError(try sut.deactivate(id: "ghost")) { error in
            XCTAssertEqual(
                error as? PluginRegistryError,
                PluginRegistryError.pluginNotFound(id: "ghost")
            )
        }
    }

    func test_activate_already_active_plugin_is_idempotent() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))
        try sut.activate(id: "slack")

        // Act — activating again should not throw or change state
        XCTAssertNoThrow(try sut.activate(id: "slack"))
        XCTAssertTrue(sut.isActive(id: "slack"))
    }

    func test_deactivate_already_inactive_plugin_is_idempotent() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))

        // Act — deactivating an already-inactive plugin should not throw
        XCTAssertNoThrow(try sut.deactivate(id: "slack"))
        XCTAssertFalse(sut.isActive(id: "slack"))
    }

    // MARK: - getActivePlugins

    func test_getActivePlugins_returns_empty_when_none_active() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))

        // Act
        let active = sut.getActivePlugins()

        // Assert
        XCTAssertTrue(active.isEmpty)
    }

    func test_getActivePlugins_returns_only_active_plugins() throws {
        // Arrange
        try sut.register(MockPlugin(id: "slack"))
        try sut.register(MockPlugin(id: "github"))
        try sut.register(MockPlugin(id: "jira"))
        try sut.activate(id: "slack")
        try sut.activate(id: "jira")

        // Act
        let active = sut.getActivePlugins()
        let activeIds = active.map { $0.id }.sorted()

        // Assert
        XCTAssertEqual(activeIds, ["jira", "slack"])
    }
}
