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
                DashboardMiniBox(
                    systemImage: "chart.bar.fill",
                    text: summary.activitySummaryLine
                )
                DashboardMiniBox(
                    systemImage: "face.smiling",
                    text: summary.moodTrendLine
                )
                DashboardMiniBox(
                    systemImage: "target",
                    label: "Today's focus",
                    text: summary.todaysFocusLine
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
