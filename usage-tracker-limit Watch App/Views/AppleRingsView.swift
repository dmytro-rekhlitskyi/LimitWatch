import SwiftUI

struct AppleRingsView: View {
    let data: ClaudeUsageData
    var onRefresh: (() -> Void)?

    private let outerColors: [Color] = [
        Color(red: 1.0, green: 0.18, blue: 0.18),
        Color(red: 1.0, green: 0.55, blue: 0.0)
    ]
    private let innerColors: [Color] = [
        Color(red: 0.0, green: 0.88, blue: 0.62),
        Color(red: 0.0, green: 0.50, blue: 1.0)
    ]

    private let outerWidth: CGFloat = 18
    private let innerWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ringsGroup

                Spacer()

                labelsRow
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
            }
        }
        .onTapGesture(count: 2) {
            onRefresh?()
        }
    }

    // MARK: - Rings (centered)

    private var ringsGroup: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let outerRadius = (size / 2) - outerWidth / 2
            let innerRadius = outerRadius - outerWidth / 2 - innerWidth / 2 - 4

            ZStack {
                // Outer track
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: outerWidth)
                    .frame(width: outerRadius * 2, height: outerRadius * 2)

                // Outer fill — 5h
                Circle()
                    .trim(from: 0, to: CGFloat(min(data.fiveHourPercentage / 100, 1)))
                    .stroke(
                        AngularGradient(colors: outerColors, center: .center),
                        style: StrokeStyle(lineWidth: outerWidth, lineCap: .round)
                    )
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: data.fiveHourPercentage)

                // Inner track
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: innerWidth)
                    .frame(width: innerRadius * 2, height: innerRadius * 2)

                // Inner fill — 7d
                Circle()
                    .trim(from: 0, to: CGFloat(min(data.sevenDayPercentage / 100, 1)))
                    .stroke(
                        AngularGradient(colors: innerColors, center: .center),
                        style: StrokeStyle(lineWidth: innerWidth, lineCap: .round)
                    )
                    .frame(width: innerRadius * 2, height: innerRadius * 2)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: data.sevenDayPercentage)

                // Center percentages
                VStack(spacing: 1) {
                    Text("\(Int(data.fiveHourPercentage.rounded()))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(Int(data.sevenDayPercentage.rounded()))%")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 140)
    }

    // MARK: - Labels (bottom)

    private var labelsRow: some View {
        HStack(spacing: 0) {
            ringLabel(dot: outerColors[0], title: "5h", resets: data.fiveHourResetsAt)
            Spacer()
            ringLabel(dot: innerColors[0], title: "7d", resets: data.sevenDayResetsAt)
        }
    }

    private func ringLabel(dot: Color, title: String, resets: Date?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Circle()
                    .fill(dot)
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            if let resets {
                Text("Resets \(resets, style: .relative)")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }
}

#Preview {
    AppleRingsView(data: .preview)
}
