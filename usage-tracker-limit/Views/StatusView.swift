import SwiftUI

struct StatusView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if appState.isAuthenticated {
                        usageCards
                        lastUpdatedLabel
                    } else {
                        notSignedInCard
                    }
                }
                .padding()
            }
            .navigationTitle("Claude Usage")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appState.isAuthenticated {
                        Button {
                            appState.fetchUsage()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(appState.isLoading)
                    }
                }
            }
            .overlay {
                if appState.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") { appState.errorMessage = nil }
        } message: {
            Text(appState.errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var usageCards: some View {
        VStack(spacing: 16) {
            UsageCard(
                title: "5-Hour Limit",
                subtitle: "Short-term window",
                percentage: appState.usageData.fiveHourPercentage,
                resetsAt: appState.usageData.fiveHourResetsAt,
                accentColor: progressColor(appState.usageData.fiveHourPercentage)
            )
            UsageCard(
                title: "Weekly Limit",
                subtitle: "7-day window",
                percentage: appState.usageData.sevenDayPercentage,
                resetsAt: appState.usageData.sevenDayResetsAt,
                accentColor: progressColor(appState.usageData.sevenDayPercentage)
            )
        }
    }

    private var lastUpdatedLabel: some View {
        let date = appState.usageData.lastUpdated
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let text = formatter.localizedString(for: date, relativeTo: Date())
        return Text("Updated \(text)")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var notSignedInCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Not signed in")
                .font(.headline)
            Text("Go to Account tab to connect your Claude account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func progressColor(_ pct: Double) -> Color {
        if pct >= 90 { return .red }
        if pct >= 70 { return .orange }
        return Color(red: 0.21, green: 0.78, blue: 0.35)
    }
}

// MARK: - Usage Card

struct UsageCard: View {
    let title: String
    let subtitle: String
    let percentage: Double
    let resetsAt: Date?
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            ProgressView(value: min(percentage / 100, 1))
                .progressViewStyle(.linear)
                .tint(accentColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            if let resets = resetsAt {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Resets \(resets, style: .relative)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    StatusView()
        .environmentObject(AppState.shared)
}
