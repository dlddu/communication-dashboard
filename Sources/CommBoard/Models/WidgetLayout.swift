import Foundation
import GRDB

/// Represents the layout configuration for a plugin widget.
public struct WidgetLayout: Codable, FetchableRecord, PersistableRecord, Equatable {
    public static let databaseTableName = "widget_layout"

    public var id: String
    public var pluginId: String
    public var positionX: Int
    public var positionY: Int
    public var size: String
    public var order: Int

    public init(
        id: String = UUID().uuidString,
        pluginId: String,
        positionX: Int = 0,
        positionY: Int = 0,
        size: String = "medium",
        order: Int = 0
    ) {
        self.id = id
        self.pluginId = pluginId
        self.positionX = positionX
        self.positionY = positionY
        self.size = size
        self.order = order
    }

    enum CodingKeys: String, CodingKey {
        case id
        case pluginId = "plugin_id"
        case positionX = "position_x"
        case positionY = "position_y"
        case size
        case order
    }
}
