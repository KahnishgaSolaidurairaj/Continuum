import SwiftUI
import SwiftData

/// Parent/clinician dashboard with calendar heatmap, progress rings, and summary.
struct DashboardView: View {
    @Query(sort: \PracticeSessionRecord.timestamp, order: .reverse) private var sessions: [PracticeSessionRecord]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .padding(.top, 8)

                PracticeCalendarCard(sessionDates: sessions.map(\.timestamp))
                ProgressRingsRow(sessions: sessions)
                PracticeGraphCard(sessions: sessions)
                DashboardSummaryCard(sessions: sessions)
            }
            .padding()
        }
        .background(ContinuumTheme.dashboardPurple)
    }
}

/// Monthly calendar with darker dots on heavier practice days.
struct PracticeCalendarCard: View {
    let sessionDates: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentMonthTitle)
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(dayItems, id: \.day) { item in
                    VStack(spacing: 4) {
                        Text("\(item.day)")
                            .font(.caption)
                        Circle()
                            .fill(item.intensityColor)
                            .frame(width: 10, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var currentMonthTitle: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    private var dayItems: [CalendarDayItem] {
        let calendar = Calendar.current
        let now = Date.now
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31

        return range.map { day in
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = day
            let date = calendar.date(from: components) ?? now
            let count = sessionDates.filter { calendar.isDate($0, inSameDayAs: date) }.count
            return CalendarDayItem(day: day, sessionCount: count)
        }
    }
}

private struct CalendarDayItem {
    let day: Int
    let sessionCount: Int

    var intensityColor: Color {
        switch sessionCount {
        case 0: return .clear
        case 1: return ContinuumTheme.tabPurple.opacity(0.35)
        case 2: return ContinuumTheme.tabPurple.opacity(0.6)
        default: return ContinuumTheme.tabPurple
        }
    }
}

/// Four progress rings from the wireframe dashboard.
struct ProgressRingsRow: View {
    let sessions: [PracticeSessionRecord]

    var body: some View {
        LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
            ProgressRingView(title: "Speech Accuracy", value: speechAccuracy)
            ProgressRingView(title: "Motor Skills", value: 0.15)
            ProgressRingView(title: "Mastery on new Skills", value: masteryRate)
            ProgressRingView(title: "Listening", value: 0.01)
        }
    }

    private var speechAccuracy: Double {
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.correctness }
        return Double(total) / Double(sessions.count) / 100.0
    }

    private var masteryRate: Double {
        guard !sessions.isEmpty else { return 0 }
        let mastered = sessions.filter { $0.correctness >= 80 }.count
        return Double(mastered) / Double(sessions.count)
    }
}

/// Single donut-style progress ring.
struct ProgressRingView: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.5), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(ContinuumTheme.tabPurple, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(value * 100))%")
                    .font(.headline)
            }
            .frame(width: 88, height: 88)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Placeholder graph card for future chart integration.
struct PracticeGraphCard: View {
    let sessions: [PracticeSessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Practice over time", systemImage: "chart.xyaxis.line")
                .font(.headline)

            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.45))
                .frame(height: 180)
                .overlay {
                    if sessions.isEmpty {
                        Text("Complete a Test activity to see your graph.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        SimpleBarChart(values: sessions.prefix(7).map { Double($0.correctness) }.reversed())
                            .padding()
                    }
                }
        }
        .padding()
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Lightweight bar chart for the dashboard MVP.
struct SimpleBarChart: View {
    let values: [Double]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 4)
                    .fill(ContinuumTheme.tabPurple)
                    .frame(maxWidth: .infinity, minHeight: 4, maxHeight: 120)
                    .scaleEffect(y: max(0.05, value / 100.0), anchor: .bottom)
            }
        }
    }
}

/// Strengths / needs improvement summary card.
struct DashboardSummaryCard: View {
    let sessions: [PracticeSessionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            summaryRow(title: "Strengths", detail: strengthsText)
            summaryRow(title: "Needs Improvement", detail: needsImprovementText)
            summaryRow(title: "Recommended", detail: recommendedText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ContinuumTheme.practiceCream)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var strengthsText: String {
        guard let best = sessions.max(by: { $0.correctness < $1.correctness }) else {
            return "Complete your first practice session."
        }
        return "/\(best.targetPhoneme)/ sounds! Growth: \(best.correctness)%"
    }

    private var needsImprovementText: String {
        guard let weakest = sessions.min(by: { $0.correctness < $1.correctness }) else {
            return "Listening and Detection"
        }
        return "/\(weakest.targetPhoneme)/ — try Flash and Test again."
    }

    private var recommendedText: String {
        sessions.isEmpty ? "Start with /m/ in the Test activity." : "Repeat your lowest-scoring sound tomorrow."
    }

    private func summaryRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.bold))
            Text(detail)
                .font(.subheadline)
        }
    }
}
