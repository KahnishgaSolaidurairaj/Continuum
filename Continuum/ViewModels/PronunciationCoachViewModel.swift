import Foundation
import SwiftData

/// Orchestrates audio capture, scoring, and session persistence for the audio-only demo.
@Observable
final class PronunciationCoachViewModel {
    var selectedPhoneme: Phoneme = .m
    var isRecording = false
    var microphoneAuthorized = false
    var liveHints: [CoachingMessage] = []
    var lastScore: PronunciationScore?
    var personalizedTips: [CoachingMessage] = []
    var errorMessage: String?

    var liveAudioLevel: Float = 0
    var liveDuration: TimeInterval = 0
    var liveVoicingLevel: Float = 0

    private let audioCapture = AudioCaptureService()
    private var audioChunks: [AudioChunk] = []
    private var userProfile = UserProfileStore.load()

    init() {
        audioCapture.onChunkCaptured = { [weak self] chunk in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.audioChunks.append(chunk)
                self.updateLiveAudioMetrics()
            }
        }
        personalizedTips = userProfile.personalizedTips()
    }

    /// Requests microphone access and prepares capture services.
    func preparePermissions() async {
        microphoneAuthorized = await audioCapture.requestPermission()
        if !microphoneAuthorized {
            errorMessage = "Microphone access is required to analyze pronunciation."
        }
    }

    /// Begins a microphone capture window for the selected phoneme.
    func startRecording() {
        guard microphoneAuthorized else {
            errorMessage = "Enable microphone access in Settings to practice."
            return
        }
        guard selectedPhoneme.isAudioDemoSupported else {
            errorMessage = "Choose a supported phoneme such as /m/ or /p/."
            return
        }

        audioChunks = []
        lastScore = nil
        errorMessage = nil
        liveAudioLevel = 0
        liveDuration = 0
        liveVoicingLevel = 0

        do {
            try audioCapture.start()
            isRecording = true
        } catch {
            errorMessage = "Could not start audio capture: \(error.localizedDescription)"
        }
    }

    /// Ends capture, scores the attempt, and persists results.
    /// - Parameter modelContext: SwiftData context for session storage.
    func stopRecording(modelContext: ModelContext) {
        guard isRecording else { return }

        audioCapture.stop()
        isRecording = false

        let audio = FeatureExtractor.extractAudio(from: audioChunks)
        let score = PronunciationScorer.scoreAudioOnly(
            phoneme: selectedPhoneme,
            audio: audio
        )

        lastScore = score
        PersonalizationEngine.updateProfile(
            &userProfile,
            phoneme: selectedPhoneme,
            score: score,
            visual: FeatureExtractor.extractVisual(from: []),
            audio: audio,
            audioOnly: true
        )
        UserProfileStore.save(userProfile)
        personalizedTips = userProfile.personalizedTips()

        persistAttempt(
            modelContext: modelContext,
            audio: audio,
            score: score
        )
    }

    private func updateLiveAudioMetrics() {
        let audio = FeatureExtractor.extractAudio(from: audioChunks)
        liveAudioLevel = min(1, audio.rmsEnergy * 20)
        liveDuration = audio.duration
        liveVoicingLevel = audio.voicedEnergyRatio
        liveHints = PronunciationScorer.liveAudioHints(phoneme: selectedPhoneme, audio: audio)
    }

    private func persistAttempt(
        modelContext: ModelContext,
        audio: AudioFeatures,
        score: PronunciationScore
    ) {
        let encoder = JSONEncoder()
        let emptyVisual = FeatureExtractor.extractVisual(from: [])

        guard
            let visualData = try? encoder.encode(emptyVisual),
            let audioData = try? encoder.encode(audio),
            let ruleData = try? encoder.encode(score.messages)
        else {
            errorMessage = "Could not save session data."
            return
        }

        let summary = score.messages.map(\.text).joined(separator: " • ")
        let record = PracticeSessionRecord(
            targetPhoneme: selectedPhoneme.rawValue,
            correctness: score.correctness,
            confidence: score.confidence,
            coachingSummary: summary,
            visualFeaturesJSON: visualData,
            audioFeaturesJSON: audioData,
            ruleResultsJSON: ruleData
        )

        modelContext.insert(record)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save practice session: \(error.localizedDescription)"
        }
    }
}
