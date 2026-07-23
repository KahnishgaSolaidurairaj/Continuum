import SwiftUI

/// Soft practice-page background for the Test (try it yourself) activity.
struct AudioDemoBackgroundView: View {
    let isRecording: Bool
    let audioLevel: Float

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ContinuumTheme.homePink,
                    ContinuumTheme.testPinkSoft,
                    ContinuumTheme.homeLavender
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if isRecording {
                VStack {
                    Spacer()
                    recordingWaveform
                        .padding(.bottom, 120)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var recordingWaveform: some View {
        HStack(spacing: 5) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        index.isMultiple(of: 2)
                            ? ContinuumTheme.testMagenta.opacity(0.75)
                            : ContinuumTheme.tabPurple.opacity(0.75)
                    )
                    .frame(width: 7, height: barHeight(for: index))
            }
        }
        .frame(height: 56)
        .animation(.easeInOut(duration: 0.15), value: audioLevel)
        .accessibilityHidden(true)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base = CGFloat(10 + index % 4 * 6)
        let boost = CGFloat(audioLevel) * 36 * (index.isMultiple(of: 2) ? 1.2 : 0.8)
        return min(52, base + boost)
    }
}

/// Displays live or post-attempt coaching messages.
struct CoachingMessagesView: View {
    let messages: [CoachingMessage]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Feedback")
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.tabPurple)

            ForEach(messages.prefix(4)) { message in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: iconName(for: message.severity))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(color(for: message.severity))
                        .frame(width: 28)

                    Text(message.text)
                        .font(ContinuumTheme.kidBodyFont)
                        .foregroundStyle(ContinuumTheme.pencilLead)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ContinuumTheme.testMagenta.opacity(0.22), lineWidth: 2)
        )
        .shadow(color: ContinuumTheme.navBarShadow, radius: 8, y: 4)
    }

    private func iconName(for severity: CoachingSeverity) -> String {
        switch severity {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    private func color(for severity: CoachingSeverity) -> Color {
        switch severity {
        case .good: return ContinuumTheme.homeMintText
        case .warning: return Color.orange
        case .critical: return Color.red
        }
    }
}
