import SwiftUI

/// Shows the five most practiced sounds for the selected day.
struct TopPracticedSoundsCard: View {
    let date: Date
    let stats: [PracticedSoundStat]

    private var maxCount: Int {
        max(stats.map(\.visitCount).max() ?? 1, 1)
    }

    var body: some View {
        DashboardCard(height: DashboardLayout.statPairHeight) {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(
                    title: "Sounds practiced",
                    systemImage: "speaker.wave.2.fill",
                    subtitle: date.dashboardLabel
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if stats.isEmpty {
                            Text("No practice sounds recorded for this day.")
                                .font(DashboardTypography.body)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
                        } else {
                            ForEach(stats) { stat in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(stat.displayName)
                                            .font(DashboardTypography.body)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                        Spacer(minLength: 4)
                                        Text("\(stat.visitCount)")
                                            .font(DashboardTypography.bodyEmphasis)
                                            .foregroundStyle(ContinuumTheme.tabPurple)
                                    }

                                    GeometryReader { geometry in
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(ContinuumTheme.tabPurple.opacity(0.18))
                                            .overlay(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 7)
                                                    .fill(ContinuumTheme.tabPurple)
                                                    .frame(width: geometry.size.width * barWidth(for: stat))
                                            }
                                    }
                                    .frame(height: 14)
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

    private func barWidth(for stat: PracticedSoundStat) -> CGFloat {
        CGFloat(stat.visitCount) / CGFloat(maxCount)
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
