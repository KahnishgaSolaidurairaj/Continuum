import SwiftUI

/// Strengths and needs practice badges from rolling Test averages.
struct StrengthsNeedsCard: View {
    let strengths: [PhonemePerformanceStat]
    let needs: [PhonemePerformanceStat]

    var body: some View {
        DashboardCard(height: DashboardLayout.analysisHeight) {
            VStack(alignment: .leading, spacing: 12) {
                DashboardCardHeader(
                    title: "Analysis",
                    systemImage: "waveform.path.ecg",
                    subtitle: "Rolling last 7 days"
                )

                if strengths.isEmpty && needs.isEmpty {
                    Text("Complete more Test activities this week.")
                        .font(ContinuumTheme.kidBodyFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        HStack(alignment: .top, spacing: 16) {
                            badgeColumn(
                                title: "Strengths",
                                stats: strengths,
                                background: Color.green.opacity(0.15),
                                foreground: Color.green.opacity(0.9)
                            )

                            Divider()

                            badgeColumn(
                                title: "Needs practice",
                                stats: needs,
                                background: Color.pink.opacity(0.15),
                                foreground: Color.pink.opacity(0.95)
                            )
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func badgeColumn(
        title: String,
        stats: [PhonemePerformanceStat],
        background: Color,
        foreground: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.black)

            if stats.isEmpty {
                Text("Not enough data yet.")
                    .font(ContinuumTheme.kidCaptionFont)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(stats) { stat in
                        Text("/\(stat.phonemeLabel)/")
                            .font(ContinuumTheme.kidCaptionFont.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(background)
                            .foregroundStyle(foreground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Simple wrapping layout for phoneme pills.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: .unspecified
            )
        }
    }

    private func arrangeSubviews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxLineWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxLineWidth = max(maxLineWidth, currentX - spacing)
        }

        return (
            CGSize(width: maxLineWidth, height: currentY + rowHeight),
            positions
        )
    }
}
