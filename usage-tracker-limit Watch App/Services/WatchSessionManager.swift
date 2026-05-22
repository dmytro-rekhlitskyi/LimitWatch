import Foundation
import WatchConnectivity
import Combine
import WidgetKit

private let appGroupID = "group.com.rekhlitskiy.usagetracerlimit"
private let cacheKey = "cachedUsageData"
private let styleKey = "displayStyle"

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var usageData: ClaudeUsageData = .empty
    @Published var displayStyle: WatchDisplayStyle = .claude

    private let groupDefaults = UserDefaults(suiteName: appGroupID)

    private override init() {
        // Load persisted style
        if let raw = UserDefaults.standard.string(forKey: styleKey),
           let style = WatchDisplayStyle(rawValue: raw) {
            displayStyle = style
        }
        // Load cached usage data (try App Group first, fall back to standard)
        let defaults = UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
        if let cached = defaults.data(forKey: cacheKey),
           let decoded = try? JSONDecoder().decode(ClaudeUsageData.self, from: cached) {
            usageData = decoded
        }
        super.init()
        activateSession()
    }

    // MARK: - Session

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Request refresh from iPhone

    func requestRefresh() {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage([WCKey.requestRefresh: true], replyHandler: nil)
    }

    // MARK: - Persist

    private func persist(data: ClaudeUsageData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        // Standard UserDefaults (Watch app)
        UserDefaults.standard.set(encoded, forKey: cacheKey)
        // App Group UserDefaults (shared with Widget Extension)
        groupDefaults?.set(encoded, forKey: cacheKey)
        // Tell WidgetKit to refresh the complication timeline
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persist(style: WatchDisplayStyle) {
        UserDefaults.standard.set(style.rawValue, forKey: styleKey)
        groupDefaults?.set(style.rawValue, forKey: styleKey)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        var newData: ClaudeUsageData?
        var newStyle: WatchDisplayStyle?

        if let raw = applicationContext[WCKey.usageData] as? Data,
           let decoded = try? JSONDecoder().decode(ClaudeUsageData.self, from: raw) {
            newData = decoded
        }
        if let rawStyle = applicationContext[WCKey.displayStyle] as? String,
           let style = WatchDisplayStyle(rawValue: rawStyle) {
            newStyle = style
        }

        DispatchQueue.main.async {
            if let data = newData {
                self.usageData = data
                self.persist(data: data)
            }
            if let style = newStyle {
                self.displayStyle = style
                self.persist(style: style)
            }
        }
    }
}
