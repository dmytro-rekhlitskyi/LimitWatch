import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            StatusView()
                .tabItem {
                    Label("Status", systemImage: "chart.bar.fill")
                }

            StylePickerView()
                .tabItem {
                    Label("Watch Style", systemImage: "applewatch.watchface")
                }

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
        .tint(Color(red: 0.85, green: 0.47, blue: 0.33))
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
