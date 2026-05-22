import SwiftUI

@main
struct usage_tracker_limitApp: App {
    @StateObject private var appState = AppState.shared
    // WatchConnectivityManager must be initialized early so WCSession activates
    private let watchManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    // Trigger initial data fetch if authenticated
                    if appState.isAuthenticated {
                        appState.fetchUsage()
                    }
                }
        }
    }
}
