import Foundation

/// Calendar event structure
struct CalendarEvent: Codable {
    let id: String
    let title: String
    let description: String?
    let startTime: String
    let endTime: String
    let location: String?
}

/// Plugin for fetching calendar events
class CalendarPlugin {
    private let shellExecutor: ShellExecutor
    private let scriptCommand = "python3 scripts/fetch_calendar.py"

    init(shellExecutor: ShellExecutor) {
        self.shellExecutor = shellExecutor
    }

    func fetchEvents() async throws -> [CalendarEvent] {
        let output = try await shellExecutor.execute(command: scriptCommand)
        let data = output.data(using: .utf8)!

        struct Response: Codable {
            let events: [CalendarEvent]
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        return decoded.events
    }
}
