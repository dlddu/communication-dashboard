import XCTest

// MARK: - DBIsolationTests
//
// 테스트 간 DB 및 설정 파일이 격리되어 있는지 검증합니다.
//
// XCUITest는 앱 외부 프로세스이므로 DatabaseManager에 직접 접근할 수 없습니다.
// 대신 임시 파일 경로 생성/삭제 로직이 올바르게 동작하는지 검증하고,
// 각 테스트가 고유한 격리 경로를 사용하는지 확인합니다.

final class DBIsolationTests: UITestBase {

    // MARK: - Properties

    /// 각 테스트마다 생성되는 고유 DB 경로
    private var dbPath: String!

    /// 각 테스트마다 생성되는 고유 설정 디렉토리
    private var configDirectory: URL!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Arrange: 각 테스트마다 고유한 임시 DB 경로 생성
        // NSTemporaryDirectory() + ProcessInfo.globallyUniqueString 패턴
        let uniqueIdentifier = ProcessInfo.processInfo.globallyUniqueString
        dbPath = NSTemporaryDirectory() + "commboard_uitest_\(uniqueIdentifier).sqlite"

        // Arrange: 각 테스트마다 고유한 설정 디렉토리 생성
        configDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("commboard_config_\(uniqueIdentifier)", isDirectory: true)

        try FileManager.default.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() async throws {
        // Teardown: 임시 DB 파일 삭제
        if let dbPath = dbPath {
            try? FileManager.default.removeItem(atPath: dbPath)
        }

        // Teardown: 임시 설정 디렉토리 삭제
        if let configDirectory = configDirectory {
            try? FileManager.default.removeItem(at: configDirectory)
        }

        dbPath = nil
        configDirectory = nil

        try await super.tearDown()
    }

    // MARK: - DB Path Isolation Tests

    /// 각 테스트마다 고유한 DB 경로가 생성되어야 합니다.
    func testDBPath_IsUniquePerTest() {
        // Arrange
        let anotherUniqueId = ProcessInfo.processInfo.globallyUniqueString
        let anotherPath = NSTemporaryDirectory() + "commboard_uitest_\(anotherUniqueId).sqlite"

        // Assert: 두 경로가 서로 다른지 확인
        XCTAssertNotEqual(
            dbPath,
            anotherPath,
            "각 테스트는 고유한 DB 경로를 사용해야 합니다"
        )
    }

    /// 임시 DB 경로가 NSTemporaryDirectory 안에 위치해야 합니다.
    func testDBPath_IsInsideTemporaryDirectory() {
        // Assert
        XCTAssertTrue(
            dbPath.hasPrefix(NSTemporaryDirectory()),
            "DB 경로는 NSTemporaryDirectory 안에 있어야 합니다"
        )
    }

    /// 임시 DB 경로가 .sqlite 확장자를 가져야 합니다.
    func testDBPath_HasSQLiteExtension() {
        // Assert
        XCTAssertTrue(
            dbPath.hasSuffix(".sqlite"),
            "임시 DB 파일은 .sqlite 확장자를 가져야 합니다"
        )
    }

    /// DB 파일이 생성 전에는 존재하지 않아야 합니다.
    func testDBFile_DoesNotExist_BeforeCreation() {
        // Assert: tearDown 이전, DB 파일이 아직 생성되지 않은 상태
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: dbPath),
            "DB 파일은 생성 전에 존재하지 않아야 합니다"
        )
    }

    /// DB 파일 경로에 파일을 생성하고 삭제할 수 있어야 합니다.
    func testDBFile_CanBeCreatedAndDeleted() throws {
        // Arrange: 임시 DB 파일 생성
        let testData = Data("test".utf8)
        try testData.write(toFile: dbPath, atomically: true, encoding: .utf8)

        // Assert: 파일이 생성됨
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: dbPath),
            "DB 파일이 생성되어야 합니다"
        )

        // Act: 파일 삭제
        try FileManager.default.removeItem(atPath: dbPath)

        // Assert: 파일이 삭제됨
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: dbPath),
            "삭제 후 DB 파일이 존재하지 않아야 합니다"
        )
    }

    // MARK: - Config Directory Isolation Tests

    /// 각 테스트마다 고유한 설정 디렉토리가 생성되어야 합니다.
    func testConfigDirectory_IsUniquePerTest() {
        // Arrange
        let anotherUniqueId = ProcessInfo.processInfo.globallyUniqueString
        let anotherDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("commboard_config_\(anotherUniqueId)", isDirectory: true)

        // Assert: 두 디렉토리 경로가 다름
        XCTAssertNotEqual(
            configDirectory.path,
            anotherDir.path,
            "각 테스트는 고유한 설정 디렉토리를 사용해야 합니다"
        )
    }

    /// 설정 디렉토리가 setUp에서 생성되어야 합니다.
    func testConfigDirectory_ExistsAfterSetup() {
        // Assert
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configDirectory.path),
            "설정 디렉토리가 setUp에서 생성되어야 합니다"
        )
    }

    // MARK: - YAML Config File Isolation Tests

    /// 임시 디렉토리에 YAML 설정 파일을 생성하고 삭제할 수 있어야 합니다.
    func testYAMLConfigFile_CanBeCreatedAndDeleted() throws {
        // Arrange: 임시 YAML 파일 생성
        let yamlContent = """
        refreshInterval: 30
        theme: light
        language: ko
        """
        let configURL = configDirectory.appendingPathComponent("config.yaml")
        try yamlContent.write(to: configURL, atomically: true, encoding: .utf8)

        // Assert: 파일이 생성됨
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: configURL.path),
            "YAML 설정 파일이 생성되어야 합니다"
        )

        // Act: 디렉토리 전체 삭제 (tearDown 시뮬레이션)
        try FileManager.default.removeItem(at: configDirectory)

        // Assert: 파일과 디렉토리가 삭제됨
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: configDirectory.path),
            "tearDown 후 설정 디렉토리가 존재하지 않아야 합니다"
        )

        // Cleanup: tearDown에서 이미 삭제됐으므로 nil 처리
        configDirectory = nil
    }

    /// 플러그인 YAML 파일을 임시 디렉토리에 생성하고 격리할 수 있어야 합니다.
    func testPluginYAMLFile_IsIsolatedPerTest() throws {
        // Arrange: plugins 서브디렉토리와 플러그인 설정 파일 생성
        let pluginsDir = configDirectory.appendingPathComponent("plugins", isDirectory: true)
        try FileManager.default.createDirectory(at: pluginsDir, withIntermediateDirectories: true)

        let pluginYAML = """
        id: github
        enabled: true
        interval: 60
        """
        let pluginURL = pluginsDir.appendingPathComponent("github.yaml")
        try pluginYAML.write(to: pluginURL, atomically: true, encoding: .utf8)

        // Assert: 플러그인 파일이 생성됨
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: pluginURL.path),
            "플러그인 YAML 파일이 생성되어야 합니다"
        )

        // Act: 설정 디렉토리 전체 삭제
        try FileManager.default.removeItem(at: configDirectory)

        // Assert: 모든 파일이 삭제됨
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: pluginURL.path),
            "tearDown 후 플러그인 설정 파일이 존재하지 않아야 합니다"
        )

        configDirectory = nil
    }

    // MARK: - GloballyUniqueString Tests

    /// ProcessInfo.globallyUniqueString이 고유한 문자열을 생성해야 합니다.
    func testGloballyUniqueString_IsUnique() {
        // Arrange & Act
        let id1 = ProcessInfo.processInfo.globallyUniqueString
        let id2 = ProcessInfo.processInfo.globallyUniqueString

        // Assert
        XCTAssertNotEqual(
            id1,
            id2,
            "globallyUniqueString은 매번 다른 값을 반환해야 합니다"
        )
    }

    /// ProcessInfo.globallyUniqueString이 비어있지 않아야 합니다.
    func testGloballyUniqueString_IsNonEmpty() {
        // Act
        let uniqueId = ProcessInfo.processInfo.globallyUniqueString

        // Assert
        XCTAssertFalse(
            uniqueId.isEmpty,
            "globallyUniqueString은 비어있지 않아야 합니다"
        )
    }

    // MARK: - App Launch With Isolated DB Tests

    /// mock 모드로 앱을 실행하면 메인 윈도우가 표시되어야 합니다 (격리 설정과 함께).
    func testLaunch_WithMockModeAndIsolatedDB_ShowsMainWindow() {
        // Arrange & Act: mock 모드 실행 + 격리용 환경 변수 전달
        launchAppInMockMode(
            additionalEnvironment: [
                "UI_TEST_DB_PATH": dbPath,
                "UI_TEST_CONFIG_DIR": configDirectory.path
            ]
        )

        // Assert: 격리 설정과 함께 실행해도 메인 윈도우가 표시됨
        let mainWindow = app.windows.firstMatch
        let windowExists = mainWindow.waitForExistence(timeout: 10.0)

        XCTAssertTrue(
            windowExists,
            "격리된 DB/설정 경로와 함께 mock 모드 실행 시 메인 윈도우가 표시되어야 합니다"
        )
    }
}

// MARK: - String Extension (Write helper)

private extension String {
    func write(toFile path: String, atomically: Bool, encoding: String.Encoding) throws {
        guard let data = self.data(using: encoding) else {
            throw NSError(
                domain: "StringWriteError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "문자열을 Data로 변환할 수 없습니다"]
            )
        }
        let url = URL(fileURLWithPath: path)
        try data.write(to: url, options: atomically ? .atomic : [])
    }
}
