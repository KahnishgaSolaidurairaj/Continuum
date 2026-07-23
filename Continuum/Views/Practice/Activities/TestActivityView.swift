import SwiftUI
import SwiftData

/// Test activity: record a spoken word and receive speech-recognition feedback.
struct TestActivityView: View {
    let target: PracticeTarget

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = WordTestViewModel()

    private var testCardBorder: Color {
        ContinuumTheme.testMagenta.opacity(0.22)
    }

    var body: some View {
        ZStack {
            AudioDemoBackgroundView(
                isRecording: viewModel.isRecording,
                audioLevel: viewModel.liveAudioLevel
            )

            PracticeActivityScrollLayout {
                header

                wordPromptCard

                feedbackSection

                recordButton

                postScoreActions

                if !viewModel.testWords.isEmpty {
                    Text(viewModel.wordPositionLabel)
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.75))
                }
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

    @ViewBuilder
    private var feedbackSection: some View {
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
            instructionCard("Say **\(viewModel.currentWord)** clearly for the full bar.")
        } else if let score = viewModel.lastScore {
            overallScoreCard(score: score)
            CoachingMessagesView(messages: score.messages)
            if let heard = viewModel.heardTranscript,
               score.correctness < 70,
               !heard.isEmpty {
                instructionCard("Heard: \"\(heard)\"")
            }
        } else {
            instructionCard("Say this word clearly into the microphone.")
        }
    }

    private var header: some View {
        PracticeActivityHeader(
            title: "Try it yourself",
            subtitle: "Say the word out loud",
            detail: "Practice \(target.displayLabel)",
            borderColor: testCardBorder
        )
    }

    private var wordPromptCard: some View {
        VStack(spacing: 10) {
            Text("Say this word")
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.tabPurple)

            HighlightedWordText(
                word: viewModel.currentWord,
                highlights: FlashWordBank.highlights(for: target, word: viewModel.currentWord),
                font: .system(size: 44, weight: .bold, design: .rounded),
                baseColor: ContinuumTheme.pencilLead,
                highlightColor: ContinuumTheme.testMagenta
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .padding(PracticeActivityChrome.cardInnerPadding)
        .frame(maxWidth: .infinity)
        .practiceActivityCardStyle(borderColor: testCardBorder)
    }

    private func instructionCard(_ text: String) -> some View {
        Text(.init(text))
            .font(ContinuumTheme.kidBodyFont)
            .foregroundStyle(ContinuumTheme.pencilLead)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(PracticeActivityChrome.cardInnerPadding)
            .practiceActivityCardStyle(borderColor: testCardBorder)
    }

    private func statusCard(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(ContinuumTheme.tabPurple)

            Text(title)
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.pencilLead)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(ContinuumTheme.kidBodyFont)
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .multilineTextAlignment(.center)
        }
        .padding(PracticeActivityChrome.cardInnerPadding)
        .frame(maxWidth: .infinity)
        .practiceActivityCardStyle(borderColor: testCardBorder)
    }

    private var recordingProgressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Recording", systemImage: "mic.fill")
                    .font(ContinuumTheme.kidSubheadFont)
                    .foregroundStyle(ContinuumTheme.tabPurple)

                Spacer()

                Text(String(
                    format: "%.1f / %.1fs",
                    viewModel.liveDuration,
                    viewModel.targetRecordingDuration
                ))
                .font(ContinuumTheme.kidCaptionFont.monospacedDigit())
                .foregroundStyle(ContinuumTheme.pencilLead)
            }

            ProgressView(value: viewModel.recordingProgress)
                .tint(ContinuumTheme.testMagenta)
        }
        .padding(PracticeActivityChrome.cardInnerPadding)
        .frame(maxWidth: .infinity)
        .practiceActivityCardStyle(borderColor: testCardBorder)
    }

    private func overallScoreCard(score: PronunciationScore) -> some View {
        VStack(spacing: 10) {
            Text("Your Score")
                .font(ContinuumTheme.kidSubheadFont)
                .foregroundStyle(ContinuumTheme.tabPurple)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(score.correctness)%")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(ContinuumTheme.pencilLead)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(score.scoringMethodLabel)
                .font(ContinuumTheme.kidCaptionFont)
                .foregroundStyle(ContinuumTheme.subtitleGray)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(PracticeActivityChrome.cardInnerPadding)
        .frame(maxWidth: .infinity)
        .practiceActivityCardStyle(borderColor: testCardBorder)
    }

    private var recordButton: some View {
        Group {
            if viewModel.lastScore == nil {
                VStack(spacing: 10) {
                    PracticePrimaryButton(
                        title: viewModel.isRecording ? "Cancel" : "Start Recording",
                        systemImage: viewModel.isRecording ? "xmark.circle.fill" : "mic.circle.fill",
                        accent: viewModel.isRecording ? ContinuumTheme.tabPurple : ContinuumTheme.testMagenta
                    ) {
                        if viewModel.isRecording {
                            viewModel.cancelRecording()
                        } else {
                            viewModel.startRecording(
                                modelContext: modelContext,
                                practiceTargetID: target.id
                            )
                        }
                    }
                    .disabled(!viewModel.microphoneAuthorized || !viewModel.speechRecognitionReady || viewModel.isAnalyzing)

                    if !viewModel.isRecording {
                        Text(String(
                            format: "Recording length adjusts to the word (%.1fs for %@).",
                            viewModel.targetRecordingDuration,
                            viewModel.currentWord
                        ))
                        .font(ContinuumTheme.kidCaptionFont)
                        .foregroundStyle(ContinuumTheme.pencilLead.opacity(0.8))
                        .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var postScoreActions: some View {
        if viewModel.lastScore != nil, !viewModel.isRecording, !viewModel.isAnalyzing {
            VStack(spacing: 12) {
                PracticePrimaryButton(
                    title: "Try same word again",
                    systemImage: "arrow.counterclockwise.circle.fill",
                    accent: ContinuumTheme.testMagenta
                ) {
                    viewModel.prepareForRetry()
                }

                PracticeSecondaryButton(
                    title: "Next word",
                    systemImage: "arrow.right.circle.fill",
                    accent: ContinuumTheme.tabPurple
                ) {
                    viewModel.moveToNextWord()
                }
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
