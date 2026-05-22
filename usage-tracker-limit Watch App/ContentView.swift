import SwiftUI

struct ContentView: View {
    @StateObject private var state = WatchState()

    var body: some View {
        Group {
            switch state.style {
            case .claude:
                ClaudeStyleView(data: state.data) {
                    state.requestRefresh()
                }
            case .apple:
                AppleRingsView(data: state.data) {
                    state.requestRefresh()
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
