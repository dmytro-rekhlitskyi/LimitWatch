import Foundation

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

enum WatchDisplayStyle: String, Codable, CaseIterable, Identifiable {
    case claude = "claude"
    case apple = "apple"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude Style"
        case .apple: return "Apple Style"
        }
    }
}

enum WCKey {
    static let usageData = "usageData"
    static let displayStyle = "displayStyle"
    static let requestRefresh = "requestRefresh"
}
