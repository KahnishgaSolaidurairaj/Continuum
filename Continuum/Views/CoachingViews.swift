import SwiftUI
import SwiftData

/// Live audio meters for the simulator-friendly demo.
struct LiveAudioMetersView: View {
    let audioLevel: Float
    let duration: TimeInterval
    let voicingLevel: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            meterRow(title: "Audio level", value: audioLevel)
            meterRow(title: "Voicing", value: voicingLevel)
            HStack {
                Text("Duration")
                    .font(.caption)
                Spacer()
                Text(String(format: "%.1fs", duration))
                    .font(.caption.monospacedDigit())
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func meterRow(title: String, value: Float) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: Double(min(max(value, 0), 1)))
                .tint(.blue)
        }
    }
}

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

/// Live visual meters for lip closure, jaw opening, and rounding.
struct LiveMetersView: View {
    let lipClosure: Float
    let jawOpen: Float
    let lipRounding: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            meterRow(title: "Lip closure", value: lipClosure)
            meterRow(title: "Jaw open", value: jawOpen)
            meterRow(title: "Lip rounding", value: lipRounding)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func meterRow(title: String, value: Float) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text(String(format: "%.0f%%", value * 100))
                    .font(.caption.monospacedDigit())
            }
            ProgressView(value: Double(min(max(value, 0), 1)))
                .tint(.green)
        }
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

/// Lists saved practice attempts from SwiftData.
struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSessionRecord.timestamp, order: .reverse) private var sessions: [PracticeSessionRecord]
    @State private var exportMessage: String?

    var body: some View {
        List(sessions) { session in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("/\(session.targetPhoneme)/")
                        .font(.headline.monospaced())
                    Spacer()
                    Text("\(session.correctness)%")
                        .font(.headline)
                        .foregroundStyle(scoreColor(session.correctness))
                }
                Text(session.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.coachingSummary)
                    .font(.caption)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
        .kidFriendlyNavigationTitle("Practice History")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Export") {
                    exportSessions()
                }
                .disabled(sessions.isEmpty)
            }
        }
        .alert("Export", isPresented: exportAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportMessage ?? "")
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    private func exportSessions() {
        do {
            let url = try SessionExportService.exportAll(modelContext: modelContext)
            exportMessage = "Exported \(sessions.count) sessions to \(url.lastPathComponent)."
        } catch {
            exportMessage = error.localizedDescription
        }
    }

    private var exportAlertBinding: Binding<Bool> {
        Binding(
            get: { exportMessage != nil },
            set: { isPresented in
                if !isPresented {
                    exportMessage = nil
                }
            }
        )
    }
}
