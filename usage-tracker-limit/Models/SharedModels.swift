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

    var styleDescription: String {
        switch self {
        case .claude: return "Two progress bars with Claude Code icon"
        case .apple: return "Concentric rings like Apple Fitness"
        }
    }
}

struct OrganizationResponse: Codable {
    let uuid: String
    let name: String
}

enum WCKey {
    static let usageData = "usageData"
    static let displayStyle = "displayStyle"
    static let requestRefresh = "requestRefresh"
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case unauthorized
    case cloudflareBlocked
    case noCredentials
    case networkError
    case decodingError
    case sessionExpired
    case noOrganizationsFound

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .noData: return "No data received"
        case .unauthorized: return "Invalid session — please sign in again"
        case .cloudflareBlocked: return "Blocked by Cloudflare — try again later"
        case .noCredentials: return "Not signed in"
        case .networkError: return "Network error — check your connection"
        case .decodingError: return "Failed to parse server response"
        case .sessionExpired: return "Session expired — please sign in again"
        case .noOrganizationsFound: return "No Claude organizations found"
        }
    }
}
