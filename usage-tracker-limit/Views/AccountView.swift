import SwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @State private var showWebLogin = false
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationView {
            List {
                if appState.isAuthenticated {
                    accountSection
                    actionsSection
                } else {
                    signInSection
                }

                infoSection
            }
            .navigationTitle("Account")
        }
        .sheet(isPresented: $showWebLogin) {
            WebLoginView {
                showWebLogin = false
                appState.checkAuthentication()
            }
        }
        .confirmationDialog("Sign out?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { appState.logout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign in again to sync data with your Apple Watch.")
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        Section("Connected Account") {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.85, green: 0.47, blue: 0.33))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.organizationName.isEmpty ? "Claude Account" : appState.organizationName)
                        .font(.headline)
                    Text("Connected")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                appState.fetchUsage()
            } label: {
                Label("Refresh Data", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isLoading)

            Button(role: .destructive) {
                showLogoutConfirmation = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    private var signInSection: some View {
        Section {
            Button {
                showWebLogin = true
            } label: {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(red: 0.85, green: 0.47, blue: 0.33))
                        Text("Sign in to Claude")
                            .font(.headline)
                        Text("Connect your Claude.ai account to display usage limits on your Apple Watch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var infoSection: some View {
        Section {
            Label("Your session key is stored securely in Keychain", systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Label("Data is synced to Apple Watch automatically", systemImage: "applewatch")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Privacy")
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(AppState.shared)
}
