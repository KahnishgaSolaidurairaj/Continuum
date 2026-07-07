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
                        LiveAudioMetersView(
                            audioLevel: viewModel.liveAudioLevel,
                            duration: viewModel.liveDuration,
                            voicingLevel: viewModel.liveVoicingLevel
                        )
                        CoachingMessagesView(messages: viewModel.liveHints)
                    } else if let score = viewModel.lastScore {
                        scoreCard(score: score)
                        CoachingMessagesView(messages: score.messages)
                    } else if let phoneme = target.linkedPhoneme {
                        Text(phoneme.audioInstruction)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Text("Audio scoring is available for linked sounds like /m/, /p/, and /f/.")
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
            if let phoneme = target.linkedPhoneme {
                viewModel.selectedPhoneme = phoneme
            }
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
                .font(.title2.weight(.bold))
            Text("Practice /\(target.symbol)/")
                .font(.headline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scoreCard(score: PronunciationScore) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Accuracy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(score.correctness)%")
                    .font(.largeTitle.bold())
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Confidence")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f%%", score.confidence * 100))
                    .font(.title2.bold())
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recordButton: some View {
        Button {
            if viewModel.isRecording {
                viewModel.stopRecording(modelContext: modelContext)
                PracticeProgressStore.recordPractice()
                PracticeProgressStore.lastPracticeTargetID = target.id
            } else {
                viewModel.startRecording()
            }
        } label: {
            Label(
                viewModel.isRecording ? "Stop & Score" : "Start Recording",
                systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isRecording ? Color.red : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!viewModel.microphoneAuthorized)
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
