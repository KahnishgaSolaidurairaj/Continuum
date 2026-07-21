import SwiftUI
import SwiftData

/// Test activity: record a spoken word and receive speech-recognition feedback.
struct TestActivityView: View {
    let target: PracticeTarget

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WordTestViewModel()

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
                    wordPromptCard

                    if viewModel.isPreparingSpeech {
                        statusCard(
                            title: "Preparing speech recognition…",
                            subtitle: "This may take a moment on first launch."
                        )
                    } else if viewModel.isAnalyzing {
                        statusCard(
                            title: "Checking…",
                            subtitle: "Listening for \(viewModel.currentWord)."
                        )
                    } else if viewModel.isRecording {
                        recordingProgressCard
                        Text("Say **\(viewModel.currentWord)** clearly for the full bar.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    } else if let score = viewModel.lastScore {
                        overallScoreCard(score: score)
                        CoachingMessagesView(messages: score.messages)
                        if let heard = viewModel.heardTranscript,
                           score.correctness < 70,
                           !heard.isEmpty {
                            Text("Heard: \"\(heard)\"")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Say this word clearly.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    recordButton

                    if !viewModel.testWords.isEmpty {
                        Text(viewModel.wordPositionLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
        .task {
            viewModel.configurePracticeTarget(target)
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

    private var wordPromptCard: some View {
        VStack(spacing: 8) {
            Text("Say this word")
                .font(.caption)
                .foregroundStyle(.secondary)

            HighlightedWordText(
                word: viewModel.currentWord,
                highlights: FlashWordBank.highlights(for: target, word: viewModel.currentWord),
                font: .system(size: 42, weight: .bold, design: .rounded),
                baseColor: .primary,
                highlightColor: .orange
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusCard(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            ProgressView()
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
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
            .disabled(!viewModel.microphoneAuthorized || !viewModel.speechRecognitionReady || viewModel.isAnalyzing)

            if !viewModel.isRecording {
                Text(String(
                    format: "Recording length adjusts to the word (%.1fs for %@).",
                    viewModel.targetRecordingDuration,
                    viewModel.currentWord
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
