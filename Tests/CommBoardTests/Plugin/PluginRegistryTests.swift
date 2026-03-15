import XCTest
@testable import CommBoard

final class PluginRegistryTests: XCTestCase {

    // MARK: - Setup / Teardown

    var registry: PluginRegistry!

    override func setUp() {
        super.setUp()
        registry = PluginRegistry()
    }

    override func tearDown() {
        registry = nil
        super.tearDown()
    }

    // MARK: - Registration

    func test_register_addsPluginToRegisteredPlugins() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")

        // Act
        try registry.register(plugin)

        // Assert
        XCTAssertEqual(registry.registeredPlugins.count, 1)
        XCTAssertNotNil(registry.registeredPlugins["slack"])
    }

    func test_register_multiplePlugins_allAreStored() throws {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")
        let jira = MockPlugin(id: "jira", name: "Jira")

        // Act
        try registry.register(slack)
        try registry.register(github)
        try registry.register(jira)

        // Assert
        XCTAssertEqual(registry.registeredPlugins.count, 3)
    }

    func test_register_throwsError_whenDuplicateId() throws {
        // Arrange
        let plugin1 = MockPlugin(id: "slack", name: "Slack")
        let plugin2 = MockPlugin(id: "slack", name: "Slack v2")
        try registry.register(plugin1)

        // Act & Assert
        XCTAssertThrowsError(try registry.register(plugin2)) { error in
            guard case PluginRegistryError.pluginAlreadyRegistered(let id) = error else {
                return XCTFail("Expected pluginAlreadyRegistered error, got \(error)")
            }
            XCTAssertEqual(id, "slack")
        }
    }

    // MARK: - Unregistration

    func test_unregister_removesPluginFromRegisteredPlugins() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)

        // Act
        try registry.unregister(pluginId: "slack")

        // Assert
        XCTAssertNil(registry.registeredPlugins["slack"])
        XCTAssertEqual(registry.registeredPlugins.count, 0)
    }

    func test_unregister_throwsError_whenPluginNotFound() throws {
        // Act & Assert
        XCTAssertThrowsError(try registry.unregister(pluginId: "nonexistent")) { error in
            guard case PluginRegistryError.pluginNotFound(let id) = error else {
                return XCTFail("Expected pluginNotFound error, got \(error)")
            }
            XCTAssertEqual(id, "nonexistent")
        }
    }

    func test_unregister_alsoDeactivatesPlugin() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)
        try registry.activate(pluginId: "slack")
        XCTAssertTrue(registry.isActive(pluginId: "slack"))

        // Act
        try registry.unregister(pluginId: "slack")

        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "slack"))
    }

    // MARK: - Lookup

    func test_pluginForId_returnsPlugin_whenExists() throws {
        // Arrange
        let plugin = MockPlugin(id: "github", name: "GitHub")
        try registry.register(plugin)

        // Act
        let found = registry.plugin(for: "github")

        // Assert
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.id, "github")
    }

    func test_pluginForId_returnsNil_whenNotFound() {
        // Act
        let found = registry.plugin(for: "nonexistent")

        // Assert
        XCTAssertNil(found)
    }

    func test_allPlugins_returnsAllRegisteredPlugins() throws {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")
        try registry.register(slack)
        try registry.register(github)

        // Act
        let all = registry.allPlugins

        // Assert
        XCTAssertEqual(all.count, 2)
        let ids = Set(all.map { $0.id })
        XCTAssertTrue(ids.contains("slack"))
        XCTAssertTrue(ids.contains("github"))
    }

    func test_allPlugins_returnsEmptyArray_whenNoneRegistered() {
        // Act & Assert
        XCTAssertTrue(registry.allPlugins.isEmpty)
    }

    // MARK: - Activation

    func test_activate_marksPluginAsActive() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)

        // Act
        try registry.activate(pluginId: "slack")

        // Assert
        XCTAssertTrue(registry.isActive(pluginId: "slack"))
    }

    func test_activate_throwsError_whenPluginNotRegistered() {
        // Act & Assert
        XCTAssertThrowsError(try registry.activate(pluginId: "ghost")) { error in
            guard case PluginRegistryError.pluginNotFound(let id) = error else {
                return XCTFail("Expected pluginNotFound error, got \(error)")
            }
            XCTAssertEqual(id, "ghost")
        }
    }

    func test_activate_isIdempotent_activatingTwiceDoesNotThrow() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)
        try registry.activate(pluginId: "slack")

        // Act & Assert
        XCTAssertNoThrow(try registry.activate(pluginId: "slack"))
        XCTAssertTrue(registry.isActive(pluginId: "slack"))
    }

    // MARK: - Deactivation

    func test_deactivate_marksPluginAsInactive() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)
        try registry.activate(pluginId: "slack")

        // Act
        try registry.deactivate(pluginId: "slack")

        // Assert
        XCTAssertFalse(registry.isActive(pluginId: "slack"))
    }

    func test_deactivate_throwsError_whenPluginNotRegistered() {
        // Act & Assert
        XCTAssertThrowsError(try registry.deactivate(pluginId: "ghost")) { error in
            guard case PluginRegistryError.pluginNotFound(let id) = error else {
                return XCTFail("Expected pluginNotFound error, got \(error)")
            }
            XCTAssertEqual(id, "ghost")
        }
    }

    func test_deactivate_isIdempotent_deactivatingTwiceDoesNotThrow() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)
        try registry.activate(pluginId: "slack")
        try registry.deactivate(pluginId: "slack")

        // Act & Assert
        XCTAssertNoThrow(try registry.deactivate(pluginId: "slack"))
        XCTAssertFalse(registry.isActive(pluginId: "slack"))
    }

    // MARK: - Active plugins list

    func test_activePlugins_returnsOnlyActivePlugins() throws {
        // Arrange
        let slack = MockPlugin(id: "slack", name: "Slack")
        let github = MockPlugin(id: "github", name: "GitHub")
        let jira = MockPlugin(id: "jira", name: "Jira")
        try registry.register(slack)
        try registry.register(github)
        try registry.register(jira)
        try registry.activate(pluginId: "slack")
        try registry.activate(pluginId: "jira")

        // Act
        let active = registry.activePlugins

        // Assert
        XCTAssertEqual(active.count, 2)
        let ids = Set(active.map { $0.id })
        XCTAssertTrue(ids.contains("slack"))
        XCTAssertTrue(ids.contains("jira"))
        XCTAssertFalse(ids.contains("github"))
    }

    func test_activePlugins_returnsEmptyArray_whenNoPluginsActive() throws {
        // Arrange
        let plugin = MockPlugin(id: "slack", name: "Slack")
        try registry.register(plugin)

        // Act & Assert
        XCTAssertTrue(registry.activePlugins.isEmpty)
    }

    func test_isActive_returnsFalse_forUnregisteredPlugin() {
        // Act & Assert
        XCTAssertFalse(registry.isActive(pluginId: "nonexistent"))
    }
}
