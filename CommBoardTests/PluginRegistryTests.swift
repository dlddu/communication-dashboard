import XCTest
@testable import CommBoard

// MARK: - PluginRegistryTests
//
// PluginRegistry는 플러그인 등록/조회/활성화를 관리합니다.

final class PluginRegistryTests: XCTestCase {

    // MARK: - Properties

    var sut: PluginRegistry!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = PluginRegistry()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Helper

    private func makeMockPlugin(
        id: String = "mock-plugin",
        name: String = "Mock Plugin"
    ) -> MockPlugin {
        MockPlugin(id: id, name: name)
    }

    // MARK: - Registration Tests

    func testRegister_SinglePlugin_Succeeds() {
        // Arrange
        let plugin = makeMockPlugin(id: "plugin-1")

        // Act
        sut.register(plugin)

        // Assert
        XCTAssertEqual(sut.allPlugins.count, 1, "플러그인 1개가 등록되어야 합니다")
    }

    func testRegister_MultiplePlugins_AllRegistered() {
        // Arrange
        let plugin1 = makeMockPlugin(id: "plugin-1", name: "Plugin One")
        let plugin2 = makeMockPlugin(id: "plugin-2", name: "Plugin Two")
        let plugin3 = makeMockPlugin(id: "plugin-3", name: "Plugin Three")

        // Act
        sut.register(plugin1)
        sut.register(plugin2)
        sut.register(plugin3)

        // Assert
        XCTAssertEqual(sut.allPlugins.count, 3, "플러그인 3개가 모두 등록되어야 합니다")
    }

    func testRegister_DuplicateId_OverwritesExisting() {
        // Arrange
        let original = makeMockPlugin(id: "plugin-1", name: "Original")
        let duplicate = makeMockPlugin(id: "plugin-1", name: "Duplicate")

        // Act
        sut.register(original)
        sut.register(duplicate)

        // Assert
        XCTAssertEqual(sut.allPlugins.count, 1, "동일 ID 재등록 시 1개만 존재해야 합니다")
        let found = sut.plugin(withId: "plugin-1")
        XCTAssertEqual(found?.name, "Duplicate", "재등록 시 새 플러그인으로 덮어써져야 합니다")
    }

    func testRegister_EmptyRegistry_HasZeroPlugins() {
        // Assert
        XCTAssertEqual(sut.allPlugins.count, 0, "초기 상태에서 플러그인이 없어야 합니다")
    }

    // MARK: - Lookup Tests

    func testPlugin_WithId_ReturnsCorrectPlugin() {
        // Arrange
        let plugin = makeMockPlugin(id: "target-plugin", name: "Target")
        sut.register(plugin)

        // Act
        let found = sut.plugin(withId: "target-plugin")

        // Assert
        XCTAssertNotNil(found, "등록된 플러그인이 ID로 조회되어야 합니다")
        XCTAssertEqual(found?.name, "Target")
    }

    func testPlugin_WithNonExistentId_ReturnsNil() {
        // Act
        let found = sut.plugin(withId: "nonexistent-plugin")

        // Assert
        XCTAssertNil(found, "존재하지 않는 ID로 조회 시 nil이 반환되어야 합니다")
    }

    func testPlugin_WithId_AmongMultiplePlugins_ReturnsCorrectOne() {
        // Arrange
        sut.register(makeMockPlugin(id: "plugin-a", name: "Plugin A"))
        sut.register(makeMockPlugin(id: "plugin-b", name: "Plugin B"))
        sut.register(makeMockPlugin(id: "plugin-c", name: "Plugin C"))

        // Act
        let found = sut.plugin(withId: "plugin-b")

        // Assert
        XCTAssertEqual(found?.id, "plugin-b", "여러 플러그인 중 올바른 플러그인이 반환되어야 합니다")
        XCTAssertEqual(found?.name, "Plugin B")
    }

    // MARK: - Activation / Deactivation Tests

    func testActivate_RegisteredPlugin_Succeeds() {
        // Arrange
        let plugin = makeMockPlugin(id: "plugin-1")
        sut.register(plugin)

        // Act
        sut.activate(pluginId: "plugin-1")

        // Assert
        XCTAssertTrue(
            sut.isActive(pluginId: "plugin-1"),
            "활성화된 플러그인은 isActive가 true여야 합니다"
        )
    }

    func testDeactivate_ActivePlugin_Succeeds() {
        // Arrange
        let plugin = makeMockPlugin(id: "plugin-1")
        sut.register(plugin)
        sut.activate(pluginId: "plugin-1")

        // Act
        sut.deactivate(pluginId: "plugin-1")

        // Assert
        XCTAssertFalse(
            sut.isActive(pluginId: "plugin-1"),
            "비활성화된 플러그인은 isActive가 false여야 합니다"
        )
    }

    func testPlugin_IsInactive_ByDefault_AfterRegistration() {
        // Arrange
        let plugin = makeMockPlugin(id: "plugin-1")
        sut.register(plugin)

        // Assert
        XCTAssertFalse(
            sut.isActive(pluginId: "plugin-1"),
            "등록 직후 플러그인은 기본적으로 비활성 상태여야 합니다"
        )
    }

    func testActivate_NonExistentPlugin_DoesNotCrash() {
        // Act & Assert: 존재하지 않는 플러그인 활성화 시 크래시가 없어야 합니다
        XCTAssertNoThrow(
            sut.activate(pluginId: "nonexistent-plugin"),
            "존재하지 않는 플러그인 활성화 시 에러가 발생하면 안 됩니다"
        )
        XCTAssertFalse(sut.isActive(pluginId: "nonexistent-plugin"))
    }

    func testDeactivate_NonExistentPlugin_DoesNotCrash() {
        // Act & Assert
        XCTAssertNoThrow(
            sut.deactivate(pluginId: "nonexistent-plugin"),
            "존재하지 않는 플러그인 비활성화 시 에러가 발생하면 안 됩니다"
        )
    }

    func testActivateMultiplePlugins_EachIsActive() {
        // Arrange
        sut.register(makeMockPlugin(id: "plugin-a"))
        sut.register(makeMockPlugin(id: "plugin-b"))
        sut.register(makeMockPlugin(id: "plugin-c"))

        // Act
        sut.activate(pluginId: "plugin-a")
        sut.activate(pluginId: "plugin-b")

        // Assert
        XCTAssertTrue(sut.isActive(pluginId: "plugin-a"), "plugin-a가 활성 상태여야 합니다")
        XCTAssertTrue(sut.isActive(pluginId: "plugin-b"), "plugin-b가 활성 상태여야 합니다")
        XCTAssertFalse(sut.isActive(pluginId: "plugin-c"), "plugin-c는 비활성 상태여야 합니다")
    }

    // MARK: - All Plugins List Tests

    func testAllPlugins_ReturnsAllRegisteredPlugins() {
        // Arrange
        let pluginIds = ["plugin-a", "plugin-b", "plugin-c"]
        for id in pluginIds {
            sut.register(makeMockPlugin(id: id))
        }

        // Act
        let all = sut.allPlugins

        // Assert
        XCTAssertEqual(all.count, pluginIds.count, "등록된 모든 플러그인이 반환되어야 합니다")
        let allIds = all.map { $0.id }
        for id in pluginIds {
            XCTAssertTrue(allIds.contains(id), "'\(id)' 플러그인이 목록에 포함되어야 합니다")
        }
    }

    func testActivePlugins_ReturnsOnlyActivePlugins() {
        // Arrange
        sut.register(makeMockPlugin(id: "plugin-a"))
        sut.register(makeMockPlugin(id: "plugin-b"))
        sut.register(makeMockPlugin(id: "plugin-c"))
        sut.activate(pluginId: "plugin-a")
        sut.activate(pluginId: "plugin-c")

        // Act
        let active = sut.activePlugins

        // Assert
        XCTAssertEqual(active.count, 2, "활성 플러그인 2개만 반환되어야 합니다")
        let activeIds = active.map { $0.id }
        XCTAssertTrue(activeIds.contains("plugin-a"))
        XCTAssertTrue(activeIds.contains("plugin-c"))
        XCTAssertFalse(activeIds.contains("plugin-b"))
    }

    func testAllPlugins_AfterUnregister_DoesNotContainUnregistered() {
        // Arrange
        sut.register(makeMockPlugin(id: "plugin-1"))
        sut.register(makeMockPlugin(id: "plugin-2"))

        // Act
        sut.unregister(pluginId: "plugin-1")

        // Assert
        XCTAssertEqual(sut.allPlugins.count, 1, "등록 해제 후 1개만 남아야 합니다")
        XCTAssertNil(sut.plugin(withId: "plugin-1"), "등록 해제된 플러그인은 조회되지 않아야 합니다")
    }

    func testUnregister_ActivePlugin_AlsoDeactivatesIt() {
        // Arrange
        sut.register(makeMockPlugin(id: "plugin-1"))
        sut.activate(pluginId: "plugin-1")

        // Act
        sut.unregister(pluginId: "plugin-1")

        // Assert
        XCTAssertFalse(
            sut.isActive(pluginId: "plugin-1"),
            "등록 해제된 플러그인은 비활성 상태여야 합니다"
        )
    }
}
