import SwiftUI
import SwiftData

/// Parent/clinician dashboard with calendar heatmap and practice analytics.
struct DashboardView: View {
    @Query(sort: \PracticeSessionRecord.timestamp, order: .reverse) private var sessions: [PracticeSessionRecord]
    @Query(sort: \ActivityEngagementRecord.endedAt, order: .reverse) private var engagements: [ActivityEngagementRecord]

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var selectedGroup: SoundGroupFilter = .all
    @State private var selectedSoundID: String?

    @State private var scrollOffset: CGFloat = 0

    private var weeklySummary: WeeklyDashboardSummary {
        DashboardAnalytics.weeklySummary(
            engagements: engagements,
            sessions: sessions,
            streakDays: PracticeProgressStore.currentStreak
        )
    }

    private var topPracticedSounds: [PracticedSoundStat] {
        DashboardAnalytics.topPracticedSounds(on: selectedDate, from: engagements)
    }

    private var strengthsAndNeeds: (strengths: [PhonemePerformanceStat], needs: [PhonemePerformanceStat]) {
        DashboardAnalytics.strengthsAndNeeds(from: sessions)
    }

    var body: some View {
        ZStack {
            DashboardScrollBackground(scrollOffset: scrollOffset)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: DashboardLayout.sectionSpacing) {
                    DashboardScrollOffsetReader()

                    Text("Dashboard")
                        .font(ContinuumTheme.kidSectionHeaderFont)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    ThisWeekSummaryCard(summary: weeklySummary)

                    TodaysFocusCard(focusLine: weeklySummary.todaysFocusLine)

                    PracticeCalendarCard(
                        engagements: engagements,
                        selectedDate: $selectedDate,
                        displayedMonth: $displayedMonth
                    )

                    HStack(alignment: .top, spacing: 10) {
                        ActivityTimeCard(engagements: engagements, date: selectedDate)
                        TopPracticedSoundsCard(date: selectedDate, stats: topPracticedSounds)
                    }

                    ActivityMoodCard(engagements: engagements, date: selectedDate)

                    SpeechAccuracyLineGraphCard(
                        date: selectedDate,
                        sessions: sessions,
                        selectedGroup: $selectedGroup,
                        selectedSoundID: $selectedSoundID
                    )

                    StrengthsNeedsCard(
                        strengths: strengthsAndNeeds.strengths,
                        needs: strengthsAndNeeds.needs
                    )
                }
                .padding(.horizontal, ContinuumTheme.pageHorizontalPadding)
                .padding(.vertical, 12)
                .padding(.bottom, ContinuumTabBar.contentBottomPadding)
            }
            .coordinateSpace(name: "dashboardScroll")
            .onPreferenceChange(DashboardScrollOffsetKey.self) { scrollOffset = $0 }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        DashboardCard(height: DashboardLayout.statPairHeight) {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(
                    title: "Time by game",
                    systemImage: "clock.fill",
                    subtitle: date.dashboardLabel
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: DashboardLayout.miniBoxSpacing) {
                        if !hasActivity {
                            Text(emptyStateMessage)
                                .font(DashboardTypography.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                        } else {
                            ForEach(PracticeActivity.allCases) { activity in
                                let duration = durations[activity] ?? 0
                                if duration > 0 {
                                    DashboardMiniBox(
                                        systemImage: activity.systemImage,
                                        text: activity.subtitle,
                                        trailingText: ActivityEngagementAnalytics.formattedMinutes(duration)
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity)
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
        DashboardCard(height: DashboardLayout.moodsHeight) {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(
                    title: "Moods",
                    systemImage: "face.smiling",
                    subtitle: date.dashboardLabel
                )

                if moodVisits.isEmpty {
                    Text(emptyStateMessage)
                        .font(ContinuumTheme.kidBodyFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    moodColumnHeaders

                    ScrollView {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(Array(PracticeActivity.allCases.enumerated()), id: \.element.id) { index, activity in
                                MoodActivityColumn(visits: moodVisits(for: activity))

                                if index < PracticeActivity.allCases.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var moodColumnHeaders: some View {
        HStack(spacing: 0) {
            ForEach(Array(PracticeActivity.allCases.enumerated()), id: \.element.id) { index, activity in
                VStack(spacing: 6) {
                    Image(systemName: activity.systemImage)
                        .font(.system(size: DashboardTypography.rowIconSize, weight: .semibold))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Text(activity.subtitle)
                        .font(DashboardTypography.label)
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)

                if index < PracticeActivity.allCases.count - 1 {
                    Color.clear.frame(width: 1)
                }
            }
        }
        .padding(.bottom, 4)
    }

    /// Returns mood visits for one practice game, newest first.
    private func moodVisits(for activity: PracticeActivity) -> [ActivityEngagementRecord] {
        moodVisits
            .filter { $0.activityRawValue == activity.rawValue }
            .sorted { $0.endedAt > $1.endedAt }
    }

    private var emptyStateMessage: String {
        Calendar.current.isDateInToday(date)
            ? "Moods appear here after finishing an activity."
            : "No moods logged for this day."
    }
}

/// One practice-game column in the moods grid.
private struct MoodActivityColumn: View {
    let visits: [ActivityEngagementRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if visits.isEmpty {
                Text("—")
                    .font(DashboardTypography.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
            } else {
                ForEach(visits, id: \.id) { visit in
                    MoodVisitEntry(visit: visit)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 6)
    }
}

/// Compact mood entry with emoji, timestamp, and practiced sound.
private struct MoodVisitEntry: View {
    let visit: ActivityEngagementRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(MoodChoice.emoji(for: visit.mood ?? ""))
                    .font(.system(size: 28))

                Text(visit.mood ?? "")
                    .font(DashboardTypography.bodyEmphasis)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Text(visit.endedAt.formatted(date: .omitted, time: .shortened))
                .font(DashboardTypography.caption)
                .foregroundStyle(.secondary)

            Text(soundLabel)
                .font(DashboardTypography.bodyEmphasis)
                .foregroundStyle(ContinuumTheme.tabPurple)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ContinuumTheme.dashboardPurple.opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(visit.activity?.subtitle ?? "Activity"), \(soundLabel), \(visit.mood ?? ""), \(visit.endedAt.formatted(date: .omitted, time: .shortened))")
    }

    private var soundLabel: String {
        PracticeSoundCatalog.sound(withID: visit.targetSoundID)?.displayName ?? visit.targetSoundID
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
        DashboardCard(height: DashboardLayout.calendarHeight) {
            VStack(alignment: .leading, spacing: 10) {
                monthHeader

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(DashboardTypography.cardSubtitle.weight(.semibold))
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
                                .frame(height: 46)
                        }
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    legendItem(color: ContinuumTheme.tabPurple, label: "Practiced")
                    legendItem(color: .gray.opacity(0.25), label: "No practice")
                }
                .font(DashboardTypography.cardSubtitle)
                .foregroundStyle(.secondary)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ContinuumTheme.tabPurple)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Previous month")

            Spacer()

            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            Spacer()

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
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
                .font(DashboardTypography.body.weight(isSelected ? .bold : .semibold))
                .foregroundStyle(isSelected ? .white : .primary)

            Circle()
                .fill(item.intensityColor)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 46)
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
        case 0: return .gray.opacity(0.25)
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
