import XCTest
@testable import CommBoard

// MARK: - StatusBarTests
//
// StatusBar의 표시 로직을 검증합니다.
// StatusBar는 대시보드 하단에 위치하며 마지막 동기화 시간과
// 플러그인별 polling 주기를 표시합니다.
//
// 검증 대상:
//   - StatusBarViewModel 초기화
//   - 마지막 동기화 시간 포맷 (날짜/시간 형식)
//   - 동기화된 적 없을 때 기본 텍스트
//   - 플러그인별 polling 주기 표시 텍스트
//   - 접근성 식별자 "status_bar_last_sync"

final class StatusBarTests: XCTestCase {

    // MARK: - Properties

    var sut: StatusBarViewModel!

    // MARK: - Setup / Teardown

    override func setUp() async throws {
        try await super.setUp()
        sut = StatusBarViewModel()
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization_LastSyncDate_IsNil() {
        // Assert
        XCTAssertNil(
            sut.lastSyncDate,
            "초기 상태에서 마지막 동기화 날짜는 nil이어야 합니다"
        )
    }

    func testInitialization_PollingIntervals_IsEmpty() {
        // Assert
        XCTAssertTrue(
            sut.pollingIntervals.isEmpty,
            "초기 상태에서 polling 주기 목록은 비어있어야 합니다"
        )
    }

    // MARK: - Last Sync Text Tests

    func testLastSyncText_WhenNeverSynced_ShowsDefaultMessage() {
        // Arrange: lastSyncDate가 nil인 상태

        // Act
        let text = sut.lastSyncText

        // Assert
        XCTAssertFalse(
            text.isEmpty,
            "동기화된 적 없을 때 기본 메시지가 표시되어야 합니다"
        )
    }

    func testLastSyncText_WhenSynced_ContainsTimePattern() {
        // Arrange
        sut.lastSyncDate = Date()

        // Act
        let text = sut.lastSyncText

        // Assert: 날짜/시간 형식 패턴(":", "/", "-" 중 하나 이상 포함)
        let containsTimePattern = text.contains(":") || text.contains("/") || text.contains("-")
        XCTAssertTrue(
            containsTimePattern,
            "마지막 동기화 시간 텍스트에 날짜/시간 형식 패턴이 포함되어야 합니다. 실제 값: \(text)"
        )
    }

    func testLastSyncText_WhenSynced_IsNotEmpty() {
        // Arrange
        sut.lastSyncDate = Date()

        // Act
        let text = sut.lastSyncText

        // Assert
        XCTAssertFalse(text.isEmpty, "동기화 후 마지막 동기화 시간 텍스트는 비어있지 않아야 합니다")
    }

    func testLastSyncText_WhenSynced_ReflectsUpdatedDate() {
        // Arrange
        let firstDate = Date(timeIntervalSince1970: 0)
        let secondDate = Date()

        sut.lastSyncDate = firstDate
        let firstText = sut.lastSyncText

        // Act
        sut.lastSyncDate = secondDate
        let secondText = sut.lastSyncText

        // Assert
        XCTAssertNotEqual(
            firstText,
            secondText,
            "동기화 날짜가 변경되면 표시 텍스트도 달라져야 합니다"
        )
    }

    // MARK: - Accessibility Identifier Tests

    func testLastSyncAccessibilityIdentifier_IsCorrect() {
        // Act
        let identifier = sut.lastSyncAccessibilityIdentifier

        // Assert
        XCTAssertEqual(
            identifier,
            "status_bar_last_sync",
            "마지막 동기화 시간 요소의 접근성 식별자는 'status_bar_last_sync'여야 합니다"
        )
    }

    // MARK: - Polling Interval Tests

    func testUpdatePollingIntervals_WithSinglePlugin_StoresInterval() {
        // Arrange
        let intervals = ["slack": 60]

        // Act
        sut.updatePollingIntervals(intervals)

        // Assert
        XCTAssertEqual(
            sut.pollingIntervals["slack"],
            60,
            "slack 플러그인의 polling 주기가 60초로 설정되어야 합니다"
        )
    }

    func testUpdatePollingIntervals_WithMultiplePlugins_StoresAll() {
        // Arrange
        let intervals = ["slack": 60, "github": 120, "jira": 300]

        // Act
        sut.updatePollingIntervals(intervals)

        // Assert
        XCTAssertEqual(sut.pollingIntervals.count, 3, "3개의 플러그인 주기가 저장되어야 합니다")
        XCTAssertEqual(sut.pollingIntervals["slack"], 60)
        XCTAssertEqual(sut.pollingIntervals["github"], 120)
        XCTAssertEqual(sut.pollingIntervals["jira"], 300)
    }

    func testPollingIntervalText_ForPlugin_FormatsCorrectly() {
        // Arrange
        sut.updatePollingIntervals(["slack": 60])

        // Act
        let text = sut.pollingIntervalText(for: "slack")

        // Assert
        XCTAssertFalse(
            text.isEmpty,
            "slack 플러그인의 polling 주기 텍스트가 비어있지 않아야 합니다"
        )
    }

    func testPollingIntervalText_ContainsNumericValue() {
        // Arrange
        sut.updatePollingIntervals(["github": 120])

        // Act
        let text = sut.pollingIntervalText(for: "github")

        // Assert: 숫자가 텍스트에 포함되는지 확인
        let containsNumber = text.contains("120") || text.contains("2분") || text.contains("2m")
        XCTAssertTrue(
            containsNumber,
            "polling 주기 텍스트에 주기값이 포함되어야 합니다. 실제 값: \(text)"
        )
    }

    func testPollingIntervalText_ForNonExistentPlugin_ReturnsEmpty() {
        // Act
        let text = sut.pollingIntervalText(for: "nonexistent-plugin")

        // Assert
        XCTAssertTrue(
            text.isEmpty,
            "존재하지 않는 플러그인의 polling 주기 텍스트는 비어있어야 합니다"
        )
    }

    // MARK: - Update Last Sync Tests

    func testUpdateLastSync_UpdatesDate() {
        // Arrange
        let syncDate = Date()
        XCTAssertNil(sut.lastSyncDate)

        // Act
        sut.updateLastSync(syncDate)

        // Assert
        XCTAssertNotNil(sut.lastSyncDate, "updateLastSync() 호출 후 lastSyncDate가 설정되어야 합니다")
        XCTAssertEqual(
            sut.lastSyncDate?.timeIntervalSince1970,
            syncDate.timeIntervalSince1970,
            accuracy: 0.001,
            "설정된 동기화 날짜가 정확히 저장되어야 합니다"
        )
    }

    func testUpdateLastSync_MultipleTimes_RetainsLatestDate() {
        // Arrange
        let firstDate = Date(timeIntervalSinceNow: -100)
        let secondDate = Date()

        // Act
        sut.updateLastSync(firstDate)
        sut.updateLastSync(secondDate)

        // Assert
        XCTAssertEqual(
            sut.lastSyncDate?.timeIntervalSince1970,
            secondDate.timeIntervalSince1970,
            accuracy: 0.001,
            "가장 최근 동기화 날짜가 유지되어야 합니다"
        )
    }

    // MARK: - Formatted Interval Tests

    func testFormattedInterval_ForSeconds_LessThanMinute() {
        // Act
        let text = sut.formattedInterval(seconds: 30)

        // Assert
        XCTAssertFalse(
            text.isEmpty,
            "30초 주기의 포맷 텍스트가 비어있지 않아야 합니다"
        )
    }

    func testFormattedInterval_ForMinutes_ReturnsMinuteRepresentation() {
        // Act
        let text = sut.formattedInterval(seconds: 60)

        // Assert: "1분", "1m", "60s", "60초" 등의 형식
        let isMinuteFormat = text.contains("1") && (
            text.contains("분") || text.contains("m") || text.contains("min")
        )
        let isSecondsFormat = text.contains("60") && (
            text.contains("초") || text.contains("s") || text.contains("sec")
        )
        XCTAssertTrue(
            isMinuteFormat || isSecondsFormat,
            "60초는 분 또는 초 단위로 표시되어야 합니다. 실제 값: \(text)"
        )
    }

    func testFormattedInterval_ForLargeValue_IsReadable() {
        // Act
        let text = sut.formattedInterval(seconds: 3600)

        // Assert
        XCTAssertFalse(
            text.isEmpty,
            "3600초(1시간) 주기의 포맷 텍스트가 비어있지 않아야 합니다"
        )
    }

    // MARK: - Sorted Polling Plugin Ids Tests

    func testSortedPollingPluginIds_WhenEmpty_ReturnsEmpty() {
        // Assert
        XCTAssertTrue(
            sut.sortedPollingPluginIds.isEmpty,
            "polling 주기가 없으면 sortedPollingPluginIds는 비어야 합니다"
        )
    }

    func testSortedPollingPluginIds_ReturnsSortedAlphabetically() {
        // Arrange
        sut.updatePollingIntervals(["slack": 60, "github": 120, "jira": 300])

        // Act
        let sorted = sut.sortedPollingPluginIds

        // Assert
        XCTAssertEqual(sorted, ["github", "jira", "slack"], "플러그인 ID가 알파벳 순으로 정렬되어야 합니다")
    }

    func testSortedPollingPluginIds_WithSinglePlugin_ReturnsOne() {
        // Arrange
        sut.updatePollingIntervals(["slack": 60])

        // Act
        let sorted = sut.sortedPollingPluginIds

        // Assert
        XCTAssertEqual(sorted.count, 1)
        XCTAssertEqual(sorted.first, "slack")
    }
}
