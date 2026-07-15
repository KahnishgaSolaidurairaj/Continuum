import SwiftUI

/// Background visual for the audio-only demo.
struct AudioDemoBackgroundView: View {
    let isRecording: Bool
    let audioLevel: Float

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.1, blue: 0.18), Color(red: 0.04, green: 0.06, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 24) {
                Image(systemName: isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 96))
                    .foregroundStyle(isRecording ? .blue : .white.opacity(0.6))
                    .symbolEffect(.pulse, isActive: isRecording)

                if isRecording {
                    HStack(spacing: 4) {
                        ForEach(0..<12, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.blue.opacity(0.8))
                                .frame(width: 6, height: barHeight(for: index))
                        }
                    }
                    .frame(height: 60)
                    .animation(.easeInOut(duration: 0.15), value: audioLevel)
                }

                Text(isRecording ? "Listening…" : "Audio Demo Mode")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .ignoresSafeArea()
    }

    private func barHeight(for index: Int) -> CGFloat {
        let base = CGFloat(8 + index % 4 * 6)
        let boost = CGFloat(audioLevel) * 40 * (index.isMultiple(of: 2) ? 1.2 : 0.8)
        return min(56, base + boost)
    }
}

/// Displays live or post-attempt coaching messages.
struct CoachingMessagesView: View {
    let messages: [CoachingMessage]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(messages.prefix(4)) { message in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: iconName(for: message.severity))
                        .foregroundStyle(color(for: message.severity))
                    Text(message.text)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
