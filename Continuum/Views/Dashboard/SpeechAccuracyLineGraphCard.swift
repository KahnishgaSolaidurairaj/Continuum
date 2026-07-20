import Charts
import SwiftUI

/// Per-day speech accuracy line graph with group and sound filters.
struct SpeechAccuracyLineGraphCard: View {
    let date: Date
    let sessions: [PracticeSessionRecord]
    @Binding var selectedGroup: SoundGroupFilter
    @Binding var selectedSoundID: String?

    @State private var selectedAttempt: Int?

    private var points: [AccuracyPoint] {
        DashboardAnalytics.accuracySeries(
            on: date,
            from: sessions,
            group: selectedGroup,
            soundID: selectedSoundID
        )
    }

    private var selectedPoint: AccuracyPoint? {
        guard let selectedAttempt else { return nil }
        return points.first { $0.attempt == selectedAttempt }
    }

    private var availableSounds: [PracticeSound] {
        DashboardAnalytics.sounds(for: selectedGroup)
    }

    var body: some View {
        DashboardCard(height: DashboardLayout.speechAccuracyHeight) {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(
                    title: "Speech accuracy",
                    systemImage: "chart.xyaxis.line",
                    subtitle: date.dashboardLabel
                )

                filterPickers

                if points.isEmpty {
                    Text("No Test attempts for this day and filter.")
                        .font(ContinuumTheme.kidBodyFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    accuracyChart

                    chartSelectionCaption
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .onChange(of: date) { _, _ in
            selectedAttempt = nil
        }
        .onChange(of: selectedGroup) { _, _ in
            selectedAttempt = nil
        }
        .onChange(of: selectedSoundID) { _, _ in
            selectedAttempt = nil
        }
    }

    private var accuracyChart: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Attempt", point.attempt),
                y: .value("Accuracy", point.percent)
            )
            .foregroundStyle(ContinuumTheme.tabPurple)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Attempt", point.attempt),
                y: .value("Accuracy", point.percent)
            )
            .foregroundStyle(ContinuumTheme.tabPurple)
            .symbolSize(selectedAttempt == point.attempt ? 110 : 55)

            if let selectedPoint, selectedPoint.attempt == point.attempt {
                RuleMark(x: .value("Attempt", point.attempt))
                    .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: 1...max(10, points.count))
        .chartXSelection(value: $selectedAttempt)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)%")
                            .font(ContinuumTheme.kidCaptionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(ContinuumTheme.kidCaptionFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedPoint,
                   let xPosition = proxy.position(forX: selectedPoint.attempt),
                   let yPosition = proxy.position(forY: selectedPoint.percent) {
                    AccuracyPointCallout(
                        attempt: selectedPoint.attempt,
                        percent: selectedPoint.percent
                    )
                    .position(
                        x: min(max(xPosition, 44), geometry.size.width - 44),
                        y: max(yPosition - 28, 18)
                    )
                }
            }
        }
        .frame(height: 200)
        .animation(.easeInOut(duration: 0.2), value: selectedAttempt)
    }

    @ViewBuilder
    private var chartSelectionCaption: some View {
        if let selectedPoint {
            Text("Attempt \(selectedPoint.attempt): \(formattedPercent(selectedPoint.percent)) accuracy")
                .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                .foregroundStyle(ContinuumTheme.tabPurple)
        } else {
            Text("Tap a data point to see exact accuracy.")
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedPercent(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value))%"
        }
        return String(format: "%.1f%%", value)
    }

    private var filterPickers: some View {
        HStack(spacing: 12) {
            Picker("Group", selection: $selectedGroup) {
                ForEach(SoundGroupFilter.allCases) { group in
                    Text(group.label).tag(group)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedGroup) { _, _ in
                selectedSoundID = nil
            }

            if selectedGroup != .all {
                Picker("Sound", selection: soundSelectionBinding) {
                    Text("All").tag(Optional<String>.none)
                    ForEach(availableSounds) { sound in
                        Text(sound.displayName).tag(Optional(sound.id))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .font(ContinuumTheme.kidCaptionFont)
    }

    private var soundSelectionBinding: Binding<String?> {
        Binding(
            get: { selectedSoundID },
            set: { selectedSoundID = $0 }
        )
    }
}

/// Floating callout shown above a selected accuracy data point.
private struct AccuracyPointCallout: View {
    let attempt: Int
    let percent: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(formattedPercent)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ContinuumTheme.tabPurple)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("Attempt \(attempt)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(ContinuumTheme.tabPurple)
        }
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    private var formattedPercent: String {
        if percent.rounded() == percent {
            return "\(Int(percent))%"
        }
        return String(format: "%.1f%%", percent)
    }
}

private extension Date {
    var dashboardLabel: String {
        if Calendar.current.isDateInToday(self) {
            return "Today"
        }
        return formatted(.dateTime.month(.abbreviated).day().year())
    }
}
