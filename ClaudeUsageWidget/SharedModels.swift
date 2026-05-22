import Foundation
import WidgetKit

struct ClaudeUsageData: Codable, Equatable {
    var fiveHourPercentage: Double
    var sevenDayPercentage: Double
    var fiveHourResetsAt: Date?
    var sevenDayResetsAt: Date?
    var lastUpdated: Date

    static let preview = ClaudeUsageData(
        fiveHourPercentage: 75,
        sevenDayPercentage: 45,
        fiveHourResetsAt: Date().addingTimeInterval(3600 * 2),
        sevenDayResetsAt: Date().addingTimeInterval(3600 * 48),
        lastUpdated: Date()
    )

    static let empty = ClaudeUsageData(
        fiveHourPercentage: 0,
        sevenDayPercentage: 0,
        fiveHourResetsAt: nil,
        sevenDayResetsAt: nil,
        lastUpdated: Date()
    )
}

struct ClaudeEntry: TimelineEntry {
    let date: Date
    let data: ClaudeUsageData
}
