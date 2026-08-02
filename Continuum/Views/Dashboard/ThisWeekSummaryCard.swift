import SwiftUI

/// Weekly summary metrics shown above the dashboard calendar.
struct ThisWeekSummaryCard: View {
    let summary: WeeklyDashboardSummary

    @Environment(\.continuumDeviceLayout) private var layout

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: DashboardLayout.miniBoxSpacing) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: DashboardTypography.headerIconSize(for: layout), weight: .semibold))
                        .foregroundStyle(ContinuumTheme.tabPurple)

                    Text("This week")
                        .font(DashboardTypography.cardTitle(for: layout))
                        .foregroundStyle(.black)

                    Text(summary.weekDateRangeLabel)
                        .font(DashboardTypography.cardSubtitle(for: layout))
                        .foregroundStyle(ContinuumTheme.tabPurple.opacity(0.85))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer(minLength: 0)
                }

                DashboardMiniBox(
                    systemImage: "flame.fill",
                    text: "\(summary.streakDays) day streak"
                )

                Group {
                    if layout.isPhone {
                        VStack(spacing: 10) {
                            statBoxes
                        }
                    } else {
                        HStack(spacing: 10) {
                            statBoxes
                        }
                    }
                }

                DashboardMiniBox(
                    systemImage: "face.smiling",
                    text: summary.moodTrendLine
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var statBoxes: some View {
        Group {
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
