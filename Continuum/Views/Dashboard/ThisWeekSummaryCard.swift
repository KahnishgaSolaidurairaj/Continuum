import SwiftUI

/// Weekly summary metrics shown above the dashboard calendar.
struct ThisWeekSummaryCard: View {
    let summary: WeeklyDashboardSummary

    var body: some View {
        DashboardCard(height: DashboardLayout.thisWeekHeight) {
            VStack(alignment: .leading, spacing: DashboardLayout.miniBoxSpacing) {
                DashboardCardHeader(title: "This week", systemImage: "calendar")

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

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(title: "Today's focus", systemImage: "target")

                Text(focusLine)
                    .font(DashboardTypography.body)
                    .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
