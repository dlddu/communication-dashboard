import Foundation

// MARK: - EditModeError

/// EditModeViewModel 작업 중 발생할 수 있는 오류를 정의합니다.
enum EditModeError: LocalizedError {
    case widgetNotFound(String)
    case indexOutOfBounds(Int)
    case pluginAlreadyPlaced(String)

    var errorDescription: String? {
        switch self {
        case .widgetNotFound(let id):
            return "위젯을 찾을 수 없습니다: \(id)"
        case .indexOutOfBounds(let index):
            return "인덱스가 범위를 벗어났습니다: \(index)"
        case .pluginAlreadyPlaced(let pluginId):
            return "이미 배치된 플러그인입니다: \(pluginId)"
        }
    }
}

// MARK: - EditModeViewModel

/// 위젯 편집 모드의 상태와 로직을 관리합니다.
/// 위젯 크기 변경, 삭제, 재정렬, 추가 및 저장 기능을 담당합니다.
class EditModeViewModel: ObservableObject {

    // MARK: - Published Properties

    /// 편집 중인 위젯 목록
    @Published var editingWidgets: [WidgetLayout]

    /// 드래그 중 여부
    @Published var isDragging: Bool = false

    /// 드래그 중인 위젯의 stableId
    @Published var draggingWidgetId: String? = nil

    /// 저장 실패 Toast 표시 여부
    @Published var showSaveFailureToast: Bool = false

    /// 미배치 플러그인 ID 목록
    @Published var unplacedPluginIds: [String]

    // MARK: - Private Properties

    private let dbManager: DatabaseManager

    // MARK: - UI Labels

    var titleBarTitle: String { "위젯 편집" }
    var addButtonLabel: String { "+ 위젯 추가" }
    var doneButtonLabel: String { "완료" }

    // MARK: - Init

    /// 편집 모드 ViewModel을 초기화합니다.
    /// - Parameters:
    ///   - widgets: 편집할 위젯 레이아웃 목록
    ///   - allPluginIds: 전체 플러그인 ID 목록
    ///   - dbManager: 데이터베이스 매니저
    init(widgets: [WidgetLayout], allPluginIds: [String], dbManager: DatabaseManager) {
        self.editingWidgets = widgets
        self.dbManager = dbManager

        // 이미 배치된 plugin_id를 제외한 미배치 목록 계산
        let placedIds = Set(widgets.map { $0.pluginId })
        self.unplacedPluginIds = allPluginIds.filter { !placedIds.contains($0) }
    }

    // MARK: - Widget Size Change

    /// 특정 위젯의 크기를 변경하고 DB에 반영합니다.
    /// - Parameters:
    ///   - widgetId: 변경할 위젯의 stableId
    ///   - newSize: 새 크기 ("small" | "medium" | "wide" | "large")
    /// - Throws: 위젯을 찾을 수 없을 때 EditModeError.widgetNotFound
    func changeWidgetSize(widgetId: String, to newSize: String) throws {
        guard let index = editingWidgets.firstIndex(where: { $0.stableId == widgetId }) else {
            throw EditModeError.widgetNotFound(widgetId)
        }

        let widget = editingWidgets[index]

        // DB 업데이트 (id가 있는 경우에만)
        if let id = widget.id {
            try dbManager.updateWidgetSize(id: id, size: newSize)
        }

        // 인메모리 상태 업데이트
        editingWidgets[index].size = newSize
    }

    // MARK: - Widget Removal

    /// 특정 위젯을 삭제하고 DB에서 제거합니다.
    /// - Parameter widgetId: 삭제할 위젯의 stableId
    /// - Throws: 위젯을 찾을 수 없을 때 EditModeError.widgetNotFound
    func removeWidget(widgetId: String) throws {
        guard let index = editingWidgets.firstIndex(where: { $0.stableId == widgetId }) else {
            throw EditModeError.widgetNotFound(widgetId)
        }

        let widget = editingWidgets[index]

        // DB에서 삭제
        if let id = widget.id {
            try dbManager.deleteWidgetLayout(id: id)
        }

        // 미배치 목록에 추가
        unplacedPluginIds.append(widget.pluginId)

        // 인메모리 상태에서 제거
        editingWidgets.remove(at: index)
    }

    // MARK: - Widget Reorder

    /// 위젯의 순서를 변경하고 모든 order 값을 DB에 반영합니다.
    /// - Parameters:
    ///   - fromIndex: 이동할 위젯의 현재 인덱스
    ///   - toIndex: 이동할 목표 인덱스
    /// - Throws: 인덱스가 범위를 벗어날 때 EditModeError.indexOutOfBounds
    func reorderWidgets(fromIndex: Int, toIndex: Int) throws {
        let count = editingWidgets.count
        guard fromIndex >= 0, fromIndex < count else {
            throw EditModeError.indexOutOfBounds(fromIndex)
        }
        guard toIndex >= 0, toIndex < count else {
            throw EditModeError.indexOutOfBounds(toIndex)
        }

        // 같은 인덱스면 아무것도 하지 않음
        guard fromIndex != toIndex else { return }

        // 배열에서 스왑
        editingWidgets.swapAt(fromIndex, toIndex)

        // 모든 위젯의 order 값을 인덱스 기반으로 재할당하고 DB 업데이트
        for (index, widget) in editingWidgets.enumerated() {
            editingWidgets[index].order = index
            if let id = widget.id {
                try dbManager.updateWidgetOrder(id: id, order: index)
            }
        }
    }

    // MARK: - Widget Add

    /// 미배치 플러그인을 새 위젯으로 추가하고 DB에 삽입합니다.
    /// - Parameter pluginId: 추가할 플러그인 ID
    /// - Throws: 이미 배치된 플러그인이면 EditModeError.pluginAlreadyPlaced
    func addWidget(pluginId: String) throws {
        // 이미 배치된 플러그인인지 확인
        guard unplacedPluginIds.contains(pluginId) else {
            throw EditModeError.pluginAlreadyPlaced(pluginId)
        }

        // 새 위젯의 order 계산 (기존 최대값 + 1)
        let maxOrder = editingWidgets.map { $0.order }.max() ?? -1
        let newOrder = maxOrder + 1

        var newWidget = WidgetLayout(
            pluginId: pluginId,
            positionX: 0,
            positionY: 0,
            size: "small",
            order: newOrder
        )

        // DB에 삽입하고 생성된 ID 반영
        let insertedId = try dbManager.insertWidgetLayout(newWidget)
        newWidget.id = insertedId

        // 인메모리 상태 업데이트
        editingWidgets.append(newWidget)
        unplacedPluginIds.removeAll { $0 == pluginId }
    }

    // MARK: - Save and Exit

    /// 현재 편집 상태를 DB에 저장합니다.
    /// 실패 시 showSaveFailureToast를 true로 설정합니다.
    func saveAndExit() async throws {
        do {
            for widget in editingWidgets {
                guard let id = widget.id else { continue }
                try dbManager.updateWidgetSize(id: id, size: widget.size)
                try dbManager.updateWidgetOrder(id: id, order: widget.order)
            }
            showSaveFailureToast = false
        } catch {
            showSaveFailureToast = true
            throw error
        }
    }

    // MARK: - Drag State

    /// 드래그 상태를 설정합니다.
    /// - Parameter widgetId: 드래그 중인 위젯의 stableId. nil이면 드래그 종료.
    func setDragging(widgetId: String?) {
        draggingWidgetId = widgetId
        isDragging = widgetId != nil
    }

    // MARK: - Drag Opacity

    /// 특정 위젯의 드래그 중 투명도를 반환합니다.
    /// - Parameter widgetId: 대상 위젯의 stableId
    /// - Returns: 드래그 중인 위젯은 0.3, 나머지는 1.0
    func draggingOpacity(for widgetId: String) -> Double {
        guard isDragging else { return 1.0 }
        return draggingWidgetId == widgetId ? 0.3 : 1.0
    }
}
