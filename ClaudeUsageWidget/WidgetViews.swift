import WidgetKit
import SwiftUI

// MARK: - Root dispatcher

struct ClaudeWidgetEntryView: View {
    let entry: ClaudeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:   CircularComplication(data: entry.data)
        case .accessoryRectangular: RectangularComplication(data: entry.data)
        case .accessoryInline:     InlineComplication(data: entry.data)
        case .accessoryCorner:     CornerComplication(data: entry.data)
        default:                   EmptyView()
        }
    }
}

// MARK: - .accessoryCircular
// Two concentric arcs: outer = 5h (thick), inner = 7d (thin)

struct CircularComplication: View {
    let data: ClaudeUsageData

    private let outerColors: [Color] = [
        Color(red: 1.0, green: 0.20, blue: 0.20),
        Color(red: 1.0, green: 0.55, blue: 0.0)
    ]
    private let innerColors: [Color] = [
        Color(red: 0.0, green: 0.88, blue: 0.62),
        Color(red: 0.0, green: 0.50, blue: 1.0)
    ]

    var body: some View {
        ZStack {
            // Outer arc — 5h
            CircleArc(
                percentage: data.fiveHourPercentage / 100,
                lineWidth: 6,
                colors: outerColors
            )

            // Inner arc — 7d
            CircleArc(
                percentage: data.sevenDayPercentage / 100,
                lineWidth: 3.5,
                colors: innerColors,
                inset: 8
            )

            // Center label
            VStack(spacing: 0) {
                Text("\(Int(data.fiveHourPercentage.rounded()))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
            }
        }
        .widgetAccentable()
    }
}

private struct CircleArc: View {
    let percentage: Double
    let lineWidth: CGFloat
    let colors: [Color]
    var inset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = (size / 2) - lineWidth / 2 - inset

            ZStack {
                // Track
                Circle()
                    .stroke(.white.opacity(0.15), lineWidth: lineWidth)
                    .frame(width: radius * 2, height: radius * 2)

                // Fill
                Circle()
                    .trim(from: 0, to: CGFloat(min(percentage, 1)))
                    .stroke(
                        AngularGradient(
                            colors: colors,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .rotationEffect(.degrees(-90))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - .accessoryRectangular
// Two custom progress bars matching iPhone app colors

struct RectangularComplication: View {
    let data: ClaudeUsageData

    private let orange = Color(red: 0.85, green: 0.47, blue: 0.33)
    private let teal   = Color(red: 0.0,  green: 0.70, blue: 0.55)

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            barRow(label: "5 Hour", percentage: data.fiveHourPercentage,
                   resetsAt: data.fiveHourResetsAt, color: orange)
            barRow(label: "7 Day",  percentage: data.sevenDayPercentage,
                   resetsAt: data.sevenDayResetsAt,  color: teal)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }

    private func barRow(label: String, percentage: Double, resetsAt: Date?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                if let resets = resetsAt {
                    Text("↺ \(resetString(resets))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text("\(Int(percentage.rounded()))%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 5)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(percentage / 100, 1)), height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private func resetString(_ date: Date) -> String {
        let diff = date.timeIntervalSinceNow
        guard diff > 0 else { return "now" }
        if diff < 3600 {
            return "\(Int(diff / 60))m"
        }
        let h = Int(diff / 3600)
        let m = Int(diff.truncatingRemainder(dividingBy: 3600) / 60)
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

// MARK: - .accessoryInline
// Single-line text: "5h 75% · 7d 45%"

struct InlineComplication: View {
    let data: ClaudeUsageData

    var body: some View {
        Text("5h \(Int(data.fiveHourPercentage.rounded()))% · 7d \(Int(data.sevenDayPercentage.rounded()))%")
            .widgetAccentable()
    }
}

// MARK: - .accessoryCorner
// Corner gauge showing 5h with label

struct CornerComplication: View {
    let data: ClaudeUsageData

    var body: some View {
        Gauge(value: data.fiveHourPercentage / 100) {
            Image(systemName: "clock")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(Color(red: 0.85, green: 0.47, blue: 0.33))
        .widgetAccentable()
    }
}

// MARK: - Previews

#Preview("Circular", as: .accessoryCircular) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeEntry(date: .now, data: .preview)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeEntry(date: .now, data: .preview)
}

#Preview("Inline", as: .accessoryInline) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeEntry(date: .now, data: .preview)
}

#if os(watchOS)
#Preview("Corner", as: .accessoryCorner) {
    ClaudeUsageWidget()
} timeline: {
    ClaudeEntry(date: .now, data: .preview)
}
#endif
