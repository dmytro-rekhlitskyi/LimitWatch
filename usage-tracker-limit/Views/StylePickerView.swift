import SwiftUI

struct StylePickerView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Text("Choose your watch display style")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(WatchDisplayStyle.allCases) { style in
                            StyleCard(
                                style: style,
                                isSelected: appState.displayStyle == style,
                                usageData: appState.usageData
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    appState.displayStyle = style
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Watch Style")
        }
    }
}

// MARK: - Style Card

struct StyleCard: View {
    let style: WatchDisplayStyle
    let isSelected: Bool
    let usageData: ClaudeUsageData
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Watch preview
                watchPreview
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                // Label row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(style.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(style.styleDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(isSelected ? Color(red: 0.85, green: 0.47, blue: 0.33) : .secondary)
                }
                .padding(16)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color(red: 0.85, green: 0.47, blue: 0.33) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var watchPreview: some View {
        switch style {
        case .claude:
            ClaudeStylePreview(data: usageData)
        case .apple:
            AppleStylePreview(data: usageData)
        }
    }
}

// MARK: - Claude Style Preview (iPhone)

struct ClaudeStylePreview: View {
    let data: ClaudeUsageData

    private let claudeOrange = Color(red: 0.85, green: 0.47, blue: 0.33)

    var body: some View {
        VStack(spacing: 16) {
            // Claude Code icon
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(claudeOrange)
                        .frame(width: 32, height: 32)
                    Text("CC")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                Text("Claude Code")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // 5-hour bar
            BarRow(
                label: "5 Hour",
                percentage: data.fiveHourPercentage,
                color: claudeOrange
            )

            // 7-day bar
            BarRow(
                label: "7 Day",
                percentage: data.sevenDayPercentage,
                color: claudeOrange.opacity(0.65)
            )
        }
        .padding(24)
    }
}

private struct BarRow: View {
    let label: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1)))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Apple Style Preview (iPhone)

struct AppleStylePreview: View {
    let data: ClaudeUsageData

    var body: some View {
        ZStack {
            // Rings
            ZStack {
                // Outer ring – 5-hour (thick)
                RingShape(percentage: data.fiveHourPercentage / 100)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color(red: 1, green: 0.2, blue: 0.2), Color(red: 1, green: 0.6, blue: 0.0)]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                // Track outer
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 20)
                    .frame(width: 120, height: 120)

                // Inner ring – 7-day (thin)
                RingShape(percentage: data.sevenDayPercentage / 100)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color(red: 0.0, green: 0.85, blue: 0.6), Color(red: 0.0, green: 0.5, blue: 1.0)]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 11, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Track inner
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 11)
                    .frame(width: 80, height: 80)
            }

            // Center labels
            VStack(spacing: 0) {
                Text("\(Int(data.fiveHourPercentage))%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(Int(data.sevenDayPercentage))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Ring Shape

struct RingShape: Shape {
    let percentage: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let endAngle = 360 * percentage - 90
        return Path { p in
            p.addArc(center: center, radius: radius,
                     startAngle: .degrees(-90), endAngle: .degrees(endAngle),
                     clockwise: false)
        }
    }
}

#Preview {
    StylePickerView()
        .environmentObject(AppState.shared)
}
