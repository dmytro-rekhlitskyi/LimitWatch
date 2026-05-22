import Foundation
import WatchConnectivity
import Combine

final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isWatchReachable = false

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendUsageData(_ data: ClaudeUsageData) {
        guard WCSession.default.activationState == .activated else { return }
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        let context: [String: Any] = [WCKey.usageData: encoded]
        try? WCSession.default.updateApplicationContext(context)
    }

    func sendDisplayStyle(_ style: WatchDisplayStyle) {
        guard WCSession.default.activationState == .activated else { return }
        let context: [String: Any] = [WCKey.displayStyle: style.rawValue]
        try? WCSession.default.updateApplicationContext(context)
    }

    func sendBoth(data: ClaudeUsageData, style: WatchDisplayStyle) {
        guard WCSession.default.activationState == .activated else { return }
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        let context: [String: Any] = [
            WCKey.usageData: encoded,
            WCKey.displayStyle: style.rawValue
        ]
        try? WCSession.default.updateApplicationContext(context)
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Watch requested a refresh — will be handled via AppState notification
        if message[WCKey.requestRefresh] != nil {
            NotificationCenter.default.post(name: .watchRequestedRefresh, object: nil)
        }
    }
}

extension Notification.Name {
    static let watchRequestedRefresh = Notification.Name("watchRequestedRefresh")
}
