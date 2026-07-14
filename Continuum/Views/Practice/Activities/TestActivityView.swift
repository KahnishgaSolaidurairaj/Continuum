import SwiftUI
import SwiftData

/// Test activity: record pronunciation and receive audio-based feedback.
struct TestActivityView: View {
    let target: PracticeTarget

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = PronunciationCoachViewModel()

    var body: some View {
        ZStack {
            AudioDemoBackgroundView(
                isRecording: viewModel.isRecording,
                audioLevel: viewModel.liveAudioLevel
            )

            VStack {
                header
                    .padding(.top, 8)

                Spacer()

                VStack(spacing: 12) {
                    if viewModel.isRecording {
                        recordingProgressCard
                        Text("Hold \(target.displayLabel) for the full bar. Your score appears when recording ends.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    } else if let score = viewModel.lastScore {
                        overallScoreCard(score: score)
                        CoachingMessagesView(messages: score.messages)
                    } else {
                        Text(target.linkedPhoneme.audioInstruction)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    recordButton
                }
                .padding()
            }
        }
        .task {
            viewModel.configurePracticeTarget(soundID: target.id, phoneme: target.linkedPhoneme)
            await viewModel.preparePermissions()
        }
        .alert("Notice", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("Try it yourself")
                .font(ContinuumTheme.kidSectionHeaderFont)
            Text("Practice \(target.displayLabel)")
                .font(ContinuumTheme.kidSubheadFont)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recordingProgressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recording")
                    .font(.caption)
                Spacer()
                Text(String(
                    format: "%.1f / %.1fs",
                    viewModel.liveDuration,
                    viewModel.targetRecordingDuration
                ))
                .font(.caption.monospacedDigit())
            }
            ProgressView(value: viewModel.recordingProgress)
                .tint(.orange)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func overallScoreCard(score: PronunciationScore) -> some View {
        VStack(spacing: 8) {
            Text("Your Score")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(score.correctness)%")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .center)

            Text(score.scoringMethodLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recordButton: some View {
        VStack(spacing: 10) {
            Button {
                if viewModel.isRecording {
                    viewModel.cancelRecording()
                } else {
                    viewModel.startRecording(
                        modelContext: modelContext,
                        practiceTargetID: target.id
                    )
                }
            } label: {
                Label(
                    viewModel.isRecording ? "Cancel" : "Start Recording",
                    systemImage: viewModel.isRecording ? "xmark.circle.fill" : "mic.circle.fill"
                )
                .font(ContinuumTheme.kidButtonFont)
                .frame(maxWidth: .infinity, minHeight: ContinuumTheme.kidMinTapHeight)
                .padding()
                .background(viewModel.isRecording ? Color.orange : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!viewModel.microphoneAuthorized)

            if !viewModel.isRecording {
                Text(String(
                    format: "Recording length matches the reference sound (%.1fs for %@).",
                    viewModel.targetRecordingDuration,
                    target.displayLabel
                ))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}
