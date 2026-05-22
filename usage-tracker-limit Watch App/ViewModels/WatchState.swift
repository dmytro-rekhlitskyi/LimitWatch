import Foundation
import Combine

@MainActor
final class WatchState: ObservableObject {
    @Published var data: ClaudeUsageData = .empty
    @Published var style: WatchDisplayStyle = .claude

    private let session = WatchSessionManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        session.$usageData
            .receive(on: RunLoop.main)
            .assign(to: &$data)

        session.$displayStyle
            .receive(on: RunLoop.main)
            .assign(to: &$style)
    }

    func requestRefresh() {
        session.requestRefresh()
    }
}
