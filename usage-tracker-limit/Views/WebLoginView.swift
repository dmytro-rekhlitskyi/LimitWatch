import SwiftUI
import WebKit
import Combine

struct WebLoginView: View {
    @StateObject private var coordinator = WebLoginCoordinator()
    var onSuccess: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                WebViewRepresentable(coordinator: coordinator)
                    .ignoresSafeArea(edges: .bottom)

                VStack {
                    statusBanner
                    Spacer()

                    if coordinator.isLoading {
                        ProgressView(value: coordinator.progress)
                            .progressViewStyle(.linear)
                            .tint(.orange)
                    }
                }
            }
            .navigationTitle("Sign in to Claude")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { coordinator.load(); coordinator.onSuccess = onSuccess }
    }

    @ViewBuilder
    private var statusBanner: some View {
        switch coordinator.state {
        case .waitingForLogin:
            Label("Sign in to capture your session", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)

        case .validating:
            Label("Validating…", systemImage: "arrow.clockwise")
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)

        case .success(let name):
            Label("Signed in as \(name)", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)

        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)

        case .loading:
            EmptyView()
        }
    }
}

// MARK: - UIViewRepresentable

struct WebViewRepresentable: UIViewRepresentable {
    let coordinator: WebLoginCoordinator

    func makeUIView(context: Context) -> WKWebView { coordinator.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Coordinator

@MainActor
final class WebLoginCoordinator: NSObject, ObservableObject {
    enum State {
        case loading
        case waitingForLogin
        case validating
        case success(name: String)
        case failed(message: String)
    }

    @Published var state: State = .loading
    @Published var isLoading = false
    @Published var progress: Double = 0

    var onSuccess: (() -> Void)?
    private(set) var webView: WKWebView!
    private var cookieTimer: Timer?
    private var progressObservation: NSKeyValueObservation?
    private var navDelegate: NavDelegate?

    private let allowedDomains: Set<String> = [
        "claude.ai", "accounts.google.com", "appleid.apple.com",
        "github.com", "login.microsoftonline.com", "challenges.cloudflare.com"
    ]

    override init() {
        super.init()
        setupWebView()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.15"
        wv.allowsBackForwardNavigationGestures = true

        let delegate = NavDelegate(coordinator: self)
        wv.navigationDelegate = delegate
        navDelegate = delegate

        progressObservation = wv.observe(\.estimatedProgress) { [weak self] wv, _ in
            DispatchQueue.main.async {
                self?.progress = wv.estimatedProgress
                self?.isLoading = wv.estimatedProgress < 1.0
            }
        }

        webView = wv
    }

    func load() {
        guard let url = URL(string: "https://claude.ai/login") else { return }
        state = .loading
        webView.load(URLRequest(url: url))
    }

    fileprivate func startCookiePolling() {
        cookieTimer?.invalidate()
        cookieTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkCookies()
        }
    }

    private func checkCookies() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            guard let cookie = cookies.first(where: { $0.name == "sessionKey" && $0.domain.contains("claude.ai") })
            else { return }

            let key = cookie.value
            DispatchQueue.main.async {
                self.cookieTimer?.invalidate()
                self.validateSession(key)
            }
        }
    }

    private func validateSession(_ sessionKey: String) {
        state = .validating
        ClaudeAPIService().fetchOrganizations(sessionKey: sessionKey) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let orgs):
                guard let org = orgs.first else {
                    state = .failed(message: "No organizations found")
                    return
                }
                KeychainService.shared.sessionKey = sessionKey
                KeychainService.shared.organizationId = org.uuid
                KeychainService.shared.organizationName = org.name

                state = .success(name: org.name)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self.onSuccess?()
                }

            case .failure(let error):
                state = .failed(message: error.localizedDescription)
                startCookiePolling()
            }
        }
    }

    // MARK: - NavDelegate

    final class NavDelegate: NSObject, WKNavigationDelegate {
        weak var coordinator: WebLoginCoordinator?
        init(coordinator: WebLoginCoordinator) { self.coordinator = coordinator }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let c = coordinator else { return }
            if case .validating = c.state { return }
            if case .success = c.state { return }
            c.state = .waitingForLogin
            c.startCookiePolling()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let ns = error as NSError
            if ns.code == NSURLErrorCancelled { return }
            coordinator?.state = .failed(message: error.localizedDescription)
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let host = navigationAction.request.url?.host?.lowercased(),
                  let c = coordinator else {
                decisionHandler(.allow); return
            }
            let allowed = c.allowedDomains.contains { host == $0 || host.hasSuffix(".\($0)") }
            if allowed {
                decisionHandler(.allow)
            } else {
                if let url = navigationAction.request.url {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
            }
        }
    }
}
