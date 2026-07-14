import SwiftUI
import SwiftData

/// Parent/clinician dashboard with calendar heatmap, progress rings, and summary.
struct DashboardView: View {
    @Query(sort: \PracticeSessionRecord.timestamp, order: .reverse) private var sessions: [PracticeSessionRecord]
    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse) private var engagements: [ActivityEngagementRecord]

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Dashboard")
                    .font(ContinuumTheme.kidSectionHeaderFont)
                    .padding(.top, 8)

                PracticeCalendarCard(
                    engagements: engagements,
                    selectedDate: $selectedDate,
                    displayedMonth: $displayedMonth
                )
                ActivityTimeCard(engagements: engagements, date: selectedDate)
                ActivityMoodCard(engagements: engagements, date: selectedDate)
                ProgressRingsRow(sessions: sessions)
                PracticeGraphCard(sessions: sessions)
                DashboardSummaryCard(sessions: sessions)
            }
            .padding()
        }
        .background(ContinuumTheme.dashboardPurple)
    }
}

/// Shows how many minutes were spent in each practice game on a selected day.
struct ActivityTimeCard: View {
    let engagements: [ActivityEngagementRecord]
    let date: Date

    private var durations: [PracticeActivity: TimeInterval] {
        ActivityEngagementAnalytics.durationsByActivity(on: date, records: engagements)
    }

    private var hasActivity: Bool {
        !durations.values.allSatisfy { $0 == 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Time by game — \(date.dashboardLabel)", systemImage: "clock.fill")
                .font(ContinuumTheme.kidSubheadFont)

            if !hasActivity {
                Text(emptyStateMessage)
                    .font(ContinuumTheme.kidBodyFont)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(PracticeActivity.allCases) { activity in
                    let duration = durations[activity] ?? 0
                    if duration > 0 {
                        HStack {
                            Text(activity.subtitle)
                                .font(ContinuumTheme.kidBodyFont)
                            Spacer()
                            Text(ActivityEngagementAnalytics.formattedMinutes(duration))
                                .font(ContinuumTheme.kidBodyFont.weight(.semibold))
                                .foregroundStyle(ContinuumTheme.tabPurple)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateMessage: String {
        Calendar.current.isDateInToday(date)
            ? "Complete a practice activity to start tracking time."
            : "No practice time recorded for this day."
    }
}

/// Lists moods logged at the end of each practice activity on a selected day.
struct ActivityMoodCard: View {
    let engagements: [ActivityEngagementRecord]
    let date: Date

    private var moodVisits: [ActivityEngagementRecord] {
        ActivityEngagementAnalytics.engagements(on: date, records: engagements)
            .filter { $0.mood != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Moods — \(date.dashboardLabel)", systemImage: "face.smiling")
                .font(ContinuumTheme.kidSubheadFont)

            if moodVisits.isEmpty {
                Text(emptyStateMessage)
                    .font(ContinuumTheme.kidBodyFont)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(moodVisits, id: \.id) { visit in
                    HStack(spacing: 12) {
                        Text(MoodChoice.emoji(for: visit.mood ?? ""))
                            .font(.title2)
                        Text("\(visit.activity?.subtitle ?? "Activity") — \(visit.mood ?? "")")
                            .font(ContinuumTheme.kidBodyFont)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateMessage: String {
        Calendar.current.isDateInToday(date)
            ? "Moods appear here after finishing an activity."
            : "No moods logged for this day."
    }
}

/// Interactive monthly calendar with selectable days and engagement intensity dots.
struct PracticeCalendarCard: View {
    let engagements: [ActivityEngagementRecord]
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            monthHeader

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(dayItems) { item in
                    if let date = item.date {
                        Button {
                            selectedDate = calendar.startOfDay(for: date)
                        } label: {
                            dayCell(for: item, date: date)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ContinuumTheme.tabPurple)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(ContinuumTheme.kidSubheadFont)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ContinuumTheme.tabPurple)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Next month")
        }
    }

    private func dayCell(for item: CalendarDayItem, date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return VStack(spacing: 4) {
            Text("\(item.day)")
                .font(ContinuumTheme.kidCaptionFont.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)

            Circle()
                .fill(item.intensityColor)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? ContinuumTheme.tabPurple : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isToday && !isSelected ? ContinuumTheme.tabPurple : .clear, lineWidth: 2)
        )
        .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(item.sessionCount) activities")
    }

    private var dayItems: [CalendarDayItem] {
        let monthStart = calendar.startOfMonth(for: displayedMonth)
        let dayRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingSpaces = (firstWeekday - calendar.firstWeekday + 7) % 7

        var items: [CalendarDayItem] = Array(repeating: CalendarDayItem(day: 0, date: nil, sessionCount: 0), count: leadingSpaces)

        for day in dayRange {
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = day
            let date = calendar.date(from: components) ?? monthStart
            let count = ActivityEngagementAnalytics.engagements(on: date, records: engagements).count
            items.append(CalendarDayItem(day: day, date: date, sessionCount: count))
        }

        return items
    }

    private func shiftMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = calendar.startOfMonth(for: newMonth)
    }
}

private struct CalendarDayItem: Identifiable {
    let day: Int
    let date: Date?
    let sessionCount: Int

    var id: String {
        if let date {
            return date.timeIntervalSince1970.description
        }
        return "spacer-\(day)"
    }

    var intensityColor: Color {
        switch sessionCount {
        case 0: return .clear
        case 1: return ContinuumTheme.tabPurple.opacity(0.35)
        case 2: return ContinuumTheme.tabPurple.opacity(0.6)
        default: return ContinuumTheme.tabPurple
        }
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

private extension Calendar {
    /// Returns the first instant of the month containing the given date.
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
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
                    .font(ContinuumTheme.kidSubheadFont)
            }
            .frame(width: 88, height: 88)

            Text(title)
                .font(ContinuumTheme.kidCaptionFont)
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
                .font(ContinuumTheme.kidSubheadFont)

            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.45))
                .frame(height: 180)
                .overlay {
                    if sessions.isEmpty {
                        Text("Complete a Test activity to see your graph.")
                            .font(ContinuumTheme.kidBodyFont)
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
                .font(ContinuumTheme.kidSubheadFont)
            Text(detail)
                .font(ContinuumTheme.kidBodyFont)
        }
    }
}
