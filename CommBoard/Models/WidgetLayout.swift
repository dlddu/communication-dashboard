import Foundation
import GRDB

/// 위젯 레이아웃 모델. widget_layout 테이블과 매핑됩니다.
struct WidgetLayout: Codable, Equatable {

    // MARK: - Properties

    var id: Int64?
    var pluginId: String
    var positionX: Double
    var positionY: Double
    var size: String
    var order: Int

    // MARK: - Init

    init(
        id: Int64? = nil,
        pluginId: String,
        positionX: Double,
        positionY: Double,
        size: String,
        order: Int
    ) {
        self.id = id
        self.pluginId = pluginId
        self.positionX = positionX
        self.positionY = positionY
        self.size = size
        self.order = order
    }
}

// MARK: - GRDB FetchableRecord

extension WidgetLayout: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        pluginId = row["plugin_id"]
        positionX = row["position_x"]
        positionY = row["position_y"]
        size = row["size"]
        order = row["order"]
    }
}

// MARK: - GRDB MutablePersistableRecord

extension WidgetLayout: MutablePersistableRecord {
    static let databaseTableName = "widget_layout"

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id
        container["plugin_id"] = pluginId
        container["position_x"] = positionX
        container["position_y"] = positionY
        container["size"] = size
        container["order"] = order
    }

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
