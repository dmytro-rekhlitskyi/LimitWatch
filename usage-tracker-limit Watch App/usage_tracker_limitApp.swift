import SwiftUI

@main
struct usage_tracker_limit_Watch_AppApp: App {
    // Initialize WatchSessionManager early so WCSession activates on launch
    private let sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
