import Foundation
import GRDB

/// `widget_layout` 테이블과 매핑되는 레코드 모델입니다.
public struct WidgetLayout: Codable, FetchableRecord, PersistableRecord {
    public static let databaseTableName = "widget_layout"
    public static let defaultSize = "medium"

    public var id: String
    public var pluginId: String
    public var positionX: Int
    public var positionY: Int
    public var size: String
    public var displayOrder: Int

    public init(
        id: String,
        pluginId: String,
        positionX: Int = 0,
        positionY: Int = 0,
        size: String = WidgetLayout.defaultSize,
        displayOrder: Int = 0
    ) {
        self.id = id
        self.pluginId = pluginId
        self.positionX = positionX
        self.positionY = positionY
        self.size = size
        self.displayOrder = displayOrder
    }

    enum CodingKeys: String, CodingKey {
        case id
        case pluginId = "plugin_id"
        case positionX = "position_x"
        case positionY = "position_y"
        case size
        case displayOrder = "display_order"
    }
}
