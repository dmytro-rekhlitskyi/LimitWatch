import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var usageData: ClaudeUsageData = .empty
    @Published var displayStyle: WatchDisplayStyle = .claude {
        didSet {
            UserDefaults.standard.set(displayStyle.rawValue, forKey: "displayStyle")
            WatchConnectivityManager.shared.sendDisplayStyle(displayStyle)
        }
    }
    @Published var isAuthenticated = false
    @Published var organizationName: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = ClaudeAPIService()
    private let keychain = KeychainService.shared
    private var refreshTimer: Timer?

    private init() {
        loadPersistedStyle()
        checkAuthentication()
        setupRefreshTimer()
        observeWatchRefreshRequests()
    }

    // MARK: - Auth

    func checkAuthentication() {
        isAuthenticated = keychain.hasCredentials
        organizationName = keychain.organizationName ?? ""
        if isAuthenticated {
            fetchUsage()
        }
    }

    func logout() {
        keychain.clearCredentials()
        isAuthenticated = false
        organizationName = ""
        usageData = .empty
    }

    // MARK: - Data Fetching

    func fetchUsage() {
        guard let sessionKey = keychain.sessionKey,
              let orgId = keychain.organizationId else { return }
        isLoading = true
        errorMessage = nil

        apiService.fetchUsage(sessionKey: sessionKey, organizationId: orgId) { [weak self] result in
            guard let self else { return }
            isLoading = false
            switch result {
            case .success(let data):
                usageData = data
                WatchConnectivityManager.shared.sendBoth(data: data, style: displayStyle)
            case .failure(let error):
                errorMessage = error.localizedDescription
                if let apiErr = error as? APIError,
                   (apiErr == .unauthorized || apiErr == .sessionExpired) {
                    isAuthenticated = false
                }
            }
        }
    }

    // MARK: - Private

    private func loadPersistedStyle() {
        if let raw = UserDefaults.standard.string(forKey: "displayStyle"),
           let style = WatchDisplayStyle(rawValue: raw) {
            displayStyle = style
        }
    }

    private func setupRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard self.isAuthenticated else { return }
                self.fetchUsage()
            }
        }
    }

    private func observeWatchRefreshRequests() {
        NotificationCenter.default.addObserver(forName: .watchRequestedRefresh, object: nil, queue: .main) { [weak self] _ in
            self?.fetchUsage()
        }
    }
}
