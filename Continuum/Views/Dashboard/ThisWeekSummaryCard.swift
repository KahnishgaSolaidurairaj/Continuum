import SwiftUI

/// Weekly summary metrics shown above the dashboard calendar.
struct ThisWeekSummaryCard: View {
    let summary: WeeklyDashboardSummary

    var body: some View {
        DashboardCard(height: DashboardLayout.thisWeekHeight) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: DashboardLayout.miniBoxSpacing) {
                    DashboardCardHeader(title: "This week", systemImage: "calendar")

                    DashboardMiniBox(
                        systemImage: "flame.fill",
                        text: "\(summary.streakDays) day streak"
                    )
                    DashboardMiniBox(
                        systemImage: "chart.bar.fill",
                        text: summary.activitySummaryLine
                    )
                    DashboardMiniBox(
                        systemImage: "face.smiling",
                        text: summary.moodTrendLine
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                DashboardMiniBox(
                    systemImage: "target",
                    label: "Today's focus",
                    text: summary.todaysFocusLine,
                    minHeight: DashboardLayout.miniBoxStackHeight
                )
                .frame(width: 158, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}
