import SwiftUI

/// Weekly summary metrics shown above the dashboard calendar.
struct ThisWeekSummaryCard: View {
    let summary: WeeklyDashboardSummary

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: DashboardLayout.miniBoxSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: DashboardTypography.headerIconSize, weight: .semibold))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Text("This week")
                        .font(DashboardTypography.cardTitle)
                        .foregroundStyle(.black)

                    Text(summary.weekDateRangeLabel)
                        .font(DashboardTypography.cardSubtitle)
                        .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)
                }

                DashboardMiniBox(
                    systemImage: "flame.fill",
                    text: "\(summary.streakDays) day streak"
                )

                HStack(spacing: 10) {
                    DashboardCompactStatBox(
                        systemImage: PracticeActivity.sandbox.systemImage,
                        title: "Sandbox",
                        valueLine: "\(summary.sandboxVisits) visits"
                    )
                    DashboardCompactStatBox(
                        systemImage: PracticeActivity.flash.systemImage,
                        title: "Flash",
                        valueLine: "\(summary.flashVisits) visits"
                    )
                    DashboardCompactStatBox(
                        systemImage: PracticeActivity.test.systemImage,
                        title: "Test",
                        valueLine: "\(summary.testAttempts) attempts"
                    )
                }

                DashboardMiniBox(
                    systemImage: "face.smiling",
                    text: summary.moodTrendLine
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// Standalone card for the current practice focus recommendation.
struct TodaysFocusCard: View {
    let focusLine: String

    @State private var focusTextHeight: CGFloat = 0

    private static let singleLineTextHeight: CGFloat = 29

    private var isMultiline: Bool {
        focusTextHeight > Self.singleLineTextHeight
    }

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(title: "Today's focus", systemImage: "target")

                Text(focusLine)
                    .font(DashboardTypography.body)
                    .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, isMultiline ? 6 : 0)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: DashboardTextHeightKey.self,
                                value: geometry.size.height
                            )
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onPreferenceChange(DashboardTextHeightKey.self) { height in
                focusTextHeight = height
            }
        }
    }
}
