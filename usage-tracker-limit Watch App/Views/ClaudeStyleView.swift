import SwiftUI

struct ClaudeStyleView: View {
    let data: ClaudeUsageData
    var onRefresh: (() -> Void)?

    private let claudeOrange = Color(red: 0.85, green: 0.47, blue: 0.33)
    private let dimOrange    = Color(red: 0.85, green: 0.47, blue: 0.33).opacity(0.55)
    private let bg           = Color(red: 0.10, green: 0.08, blue: 0.07)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 10) {
                Spacer(minLength: 16)

                progressBlock(
                    label: "5 Hour",
                    percentage: data.fiveHourPercentage,
                    resetsAt: data.fiveHourResetsAt,
                    barColor: claudeOrange
                )

                progressBlock(
                    label: "7 Day",
                    percentage: data.sevenDayPercentage,
                    resetsAt: data.sevenDayResetsAt,
                    barColor: dimOrange
                )

                Text(lastUpdatedText)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.top, 2)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 10)
        }
        .onTapGesture(count: 2) {
            onRefresh?()
        }
    }

    // MARK: - Progress block

    private func progressBlock(label: String, percentage: Double, resetsAt: Date?, barColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(percentage.rounded()))%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(percentageColor(percentage))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: 7)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.8), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1)), height: 7)
                        .animation(.easeOut(duration: 0.6), value: percentage)
                }
            }
            .frame(height: 7)

            if let resets = resetsAt {
                Text("Resets \(resets, style: .relative)")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    // MARK: - Helpers

    private var lastUpdatedText: String {
        let diff = Date().timeIntervalSince(data.lastUpdated)
        if diff < 60 { return "Updated just now" }
        if diff < 3600 { return "Updated \(Int(diff / 60))m ago" }
        return "Updated \(Int(diff / 3600))h ago"
    }

    private func percentageColor(_ pct: Double) -> Color {
        if pct >= 90 { return .red }
        if pct >= 70 { return Color(red: 1, green: 0.65, blue: 0) }
        return .white
    }
}

#Preview {
    ClaudeStyleView(data: .preview)
}
