import Foundation
import SwiftData

/// Orchestrates audio capture, scoring, and session persistence for the audio-only demo.
@Observable
final class PronunciationCoachViewModel {
    var selectedPhoneme: Phoneme = .m
    var isRecording = false
    var microphoneAuthorized = false
    var lastScore: PronunciationScore?
    var personalizedTips: [CoachingMessage] = []
    var errorMessage: String?

    var liveAudioLevel: Float = 0
    var liveDuration: TimeInterval = 0
    var liveVoicingLevel: Float = 0
    var targetRecordingDuration: TimeInterval = 0.8
    var recordingProgress: Double = 0

    private let audioCapture = AudioCaptureService()
    private let embeddingScorer = EmbeddingPronunciationScorer()
    private var audioChunks: [AudioChunk] = []
    private var userProfile = UserProfileStore.load()
    private var autoStopTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var activePracticeTargetID: String?
    private var recordingStartedAt: Date?

    init() {
        audioCapture.onChunkCaptured = { [weak self] chunk in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.audioChunks.append(chunk)
                self.updateLiveAudioMetrics()
            }
        }
        personalizedTips = userProfile.personalizedTips()
        refreshTargetDuration()
    }

    /// Requests microphone access and prepares capture services.
    func preparePermissions() async {
        microphoneAuthorized = await audioCapture.requestPermission()
        if !microphoneAuthorized {
            errorMessage = "Microphone access is required to analyze pronunciation."
        }
    }

    /// Binds the view model to a practice sound before recording.
    /// - Parameters:
    ///   - soundID: Practice sound identifier used for scoring.
    ///   - phoneme: Linked phoneme used for rule-based fallback hints.
    func configurePracticeTarget(soundID: String, phoneme: Phoneme) {
        selectedPhoneme = phoneme
        activePracticeTargetID = soundID
        refreshTargetDuration()
    }

    /// Begins a fixed-length microphone capture window for the selected phoneme.
    /// - Parameters:
    ///   - modelContext: SwiftData context used when the timer auto-stops recording.
    ///   - practiceTargetID: Letter or sound ID used for local progress tracking.
    func startRecording(modelContext: ModelContext, practiceTargetID: String) {
        guard microphoneAuthorized else {
            errorMessage = "Enable microphone access in Settings to practice."
            return
        }
        guard selectedPhoneme.isAudioDemoSupported else {
            errorMessage = "Choose a supported phoneme such as /m/ or /p/."
            return
        }

        autoStopTask?.cancel()
        audioChunks = []
        lastScore = nil
        errorMessage = nil
        liveAudioLevel = 0
        liveDuration = 0
        liveVoicingLevel = 0
        recordingProgress = 0
        recordingStartedAt = Date()
        refreshTargetDuration()
        activePracticeTargetID = practiceTargetID

        do {
            try audioCapture.start()
            isRecording = true
            startProgressUpdates()
            scheduleAutoStop(modelContext: modelContext)
        } catch {
            errorMessage = "Could not start audio capture: \(error.localizedDescription)"
        }
    }

    /// Cancels an in-progress recording without scoring it.
    func cancelRecording() {
        guard isRecording else { return }
        autoStopTask?.cancel()
        progressTask?.cancel()
        audioCapture.stop()
        isRecording = false
        audioChunks = []
        recordingProgress = 0
        liveDuration = 0
        recordingStartedAt = nil
    }

    /// Ends capture, scores the attempt, and persists results.
    /// - Parameter modelContext: SwiftData context for session storage.
    func stopRecording(modelContext: ModelContext) {
        guard isRecording else { return }

        autoStopTask?.cancel()
        progressTask?.cancel()
        let voiceProcessingWasActive = audioCapture.isVoiceProcessingActive
        audioCapture.stop()
        isRecording = false
        recordingProgress = 1
        liveDuration = targetRecordingDuration
        recordingStartedAt = nil

        let audio = FeatureExtractor.extractAudio(from: audioChunks)
        let score = PronunciationScorer.scoreAttempt(
            soundID: activePracticeTargetID ?? selectedPhoneme.modelLabel,
            phoneme: selectedPhoneme,
            audio: audio,
            chunks: audioChunks,
            embeddingScorer: embeddingScorer,
            voiceProcessingActive: voiceProcessingWasActive
        )

        lastScore = score
        PracticeProgressStore.recordPractice()
        if let activePracticeTargetID {
            PracticeProgressStore.lastPracticeTargetID = activePracticeTargetID
        }
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

    private func scheduleAutoStop(modelContext: ModelContext) {
        let duration = targetRecordingDuration
        autoStopTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled, isRecording else { return }
            stopRecording(modelContext: modelContext)
        }
    }

    private func startProgressUpdates() {
        progressTask?.cancel()
        progressTask = Task { @MainActor in
            while isRecording, let recordingStartedAt {
                let elapsed = Date().timeIntervalSince(recordingStartedAt)
                liveDuration = min(elapsed, targetRecordingDuration)
                if targetRecordingDuration > 0 {
                    recordingProgress = min(1, elapsed / targetRecordingDuration)
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    private func refreshTargetDuration() {
        if let activePracticeTargetID {
            targetRecordingDuration = PhonemeReferenceCatalog.recordingDuration(forSoundID: activePracticeTargetID)
        } else {
            targetRecordingDuration = PhonemeReferenceCatalog.targetRecordingDuration
        }
    }

    private func updateLiveAudioMetrics() {
        let audio = FeatureExtractor.extractAudio(from: audioChunks)
        liveAudioLevel = min(1, audio.rmsEnergy * 20)
        liveVoicingLevel = audio.voicedEnergyRatio
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
