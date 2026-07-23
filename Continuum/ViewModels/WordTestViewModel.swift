import Foundation
import SwiftData

/// Orchestrates word cycling, speech recognition, and scoring for the Test activity.
@Observable
final class WordTestViewModel {
    var isRecording = false
    var isAnalyzing = false
    var isPreparingSpeech = false
    var microphoneAuthorized = false
    var speechRecognitionReady = false
    var lastScore: PronunciationScore?
    var heardTranscript: String?
    var errorMessage: String?

    var liveAudioLevel: Float = 0
    var liveDuration: TimeInterval = 0
    var targetRecordingDuration: TimeInterval = 2.0
    var recordingProgress: Double = 0

    private(set) var testWords: [String] = []
    private(set) var wordIndex = 0

    var currentWord: String {
        guard !testWords.isEmpty else { return "" }
        return testWords[wordIndex % testWords.count]
    }

    var wordPositionLabel: String {
        guard !testWords.isEmpty else { return "" }
        let position = (wordIndex % testWords.count) + 1
        return "Word \(position) of \(testWords.count)"
    }

    private let audioCapture = AudioCaptureService()
    private let speechRecognition = WordSpeechRecognitionService()
    private var audioChunks: [AudioChunk] = []
    private var userProfile = UserProfileStore.load()
    private var autoStopTask: Task<Void, Never>?
    private var progressTask: Task<Void, Never>?
    private var activePracticeTarget: PracticeTarget?
    private var recordingStartedAt: Date?

    init() {
        audioCapture.onChunkCaptured = { [weak self] chunk in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.audioChunks.append(chunk)
                self.speechRecognition.append(chunk: chunk)
                self.updateLiveAudioMetrics()
            }
        }
    }

    /// Requests microphone access and prepares on-device speech recognition.
    func preparePermissions() async {
        microphoneAuthorized = await audioCapture.requestPermission()
        if !microphoneAuthorized {
            errorMessage = "Microphone access is required to analyze pronunciation."
            return
        }

        isPreparingSpeech = true
        await speechRecognition.prepare()
        isPreparingSpeech = false

        switch speechRecognition.readinessState {
        case .ready:
            speechRecognitionReady = true
        case .unavailable(let message):
            speechRecognitionReady = false
            errorMessage = message
        case .idle, .preparing:
            speechRecognitionReady = false
            errorMessage = "Speech recognition is still preparing. Try again in a moment."
        }
    }

    /// Loads the word list for the selected practice target.
    /// - Parameter target: The sound the learner is practicing.
    func configurePracticeTarget(_ target: PracticeTarget) {
        activePracticeTarget = target
        testWords = FlashWordBank.testWords(for: target)
        wordIndex = 0
        heardTranscript = nil
        refreshTargetDuration()
    }

    /// Begins a fixed-length microphone capture window for the current word.
    /// - Parameters:
    ///   - modelContext: SwiftData context used when the timer auto-stops recording.
    ///   - practiceTargetID: Letter or sound ID used for local progress tracking.
    func startRecording(modelContext: ModelContext, practiceTargetID: String) {
        guard microphoneAuthorized else {
            errorMessage = "Enable microphone access in Settings to practice."
            return
        }
        guard speechRecognitionReady else {
            errorMessage = "Preparing speech recognition…"
            return
        }
        guard !currentWord.isEmpty else {
            errorMessage = "No practice words are available for this sound."
            return
        }

        autoStopTask?.cancel()
        audioChunks = []
        lastScore = nil
        heardTranscript = nil
        errorMessage = nil
        liveAudioLevel = 0
        liveDuration = 0
        recordingProgress = 0
        recordingStartedAt = Date()
        refreshTargetDuration()

        Task { @MainActor in
            do {
                try await speechRecognition.beginSession(sampleRate: audioCapture.sampleRate)
                try audioCapture.start()
                isRecording = true
                startProgressUpdates()
                scheduleAutoStop(modelContext: modelContext, practiceTargetID: practiceTargetID)
            } catch {
                speechRecognition.cancel()
                errorMessage = "Could not start speech recognition: \(error.localizedDescription)"
            }
        }
    }

    /// Cancels an in-progress recording without scoring it.
    func cancelRecording() {
        guard isRecording else { return }
        autoStopTask?.cancel()
        progressTask?.cancel()
        audioCapture.stop()
        speechRecognition.cancel()
        isRecording = false
        audioChunks = []
        recordingProgress = 0
        liveDuration = 0
        recordingStartedAt = nil
    }

    /// Ends capture, runs speech recognition, and scores the attempt.
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
        isAnalyzing = true

        Task { @MainActor in
            defer { isAnalyzing = false }

            let audio = FeatureExtractor.extractAudio(from: audioChunks)
            if let failure = PronunciationScorer.audioQualityFailure(
                for: audio,
                chunks: audioChunks,
                voiceProcessingActive: voiceProcessingWasActive
            ) {
                speechRecognition.cancel()
                lastScore = PronunciationScore(
                    correctness: 0,
                    confidence: 0.1,
                    messages: [failure],
                    scoringMethod: .speechRecognition
                )
                return
            }

            do {
                let recognition = try await speechRecognition.finish()
                heardTranscript = recognition.transcript
                let score = WordRecognitionScorer.score(
                    WordRecognitionScorer.Input(
                        targetWord: currentWord,
                        transcript: recognition.transcript,
                        confidence: recognition.confidence
                    )
                )
                lastScore = score
                persistAttempt(
                    modelContext: modelContext,
                    audio: audio,
                    score: score
                )
            } catch {
                speechRecognition.cancel()
                errorMessage = "Speech recognition failed: \(error.localizedDescription)"
            }
        }
    }

    /// Clears the last attempt so the learner can record the current word again.
    /// - Returns: Nothing; resets score UI state for another attempt on the same word.
    func prepareForRetry() {
        lastScore = nil
        heardTranscript = nil
        errorMessage = nil
    }

    /// Advances to the next practice word and clears the previous score.
    /// - Returns: Nothing; updates `currentWord` and hides the prior score until the next attempt.
    func moveToNextWord() {
        advanceWord()
        prepareForRetry()
    }

    private func advanceWord() {
        guard !testWords.isEmpty else { return }
        wordIndex = (wordIndex + 1) % testWords.count
        refreshTargetDuration()
    }

    private func scheduleAutoStop(modelContext: ModelContext, practiceTargetID: String) {
        let duration = targetRecordingDuration
        autoStopTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled, isRecording else { return }
            PracticeProgressStore.lastPracticeTargetID = practiceTargetID
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
        targetRecordingDuration = 2.0
    }

    private func updateLiveAudioMetrics() {
        let audio = FeatureExtractor.extractAudio(from: audioChunks)
        liveAudioLevel = min(1, audio.rmsEnergy * 20)
    }

    private func persistAttempt(
        modelContext: ModelContext,
        audio: AudioFeatures,
        score: PronunciationScore
    ) {
        let encoder = JSONEncoder()

        guard
            let audioData = try? encoder.encode(audio),
            let ruleData = try? encoder.encode(score.messages),
            let phoneme = activePracticeTarget?.linkedPhoneme
        else {
            errorMessage = "Could not save session data."
            return
        }

        PracticeProgressStore.recordPractice()
        if let activePracticeTarget {
            PracticeProgressStore.lastPracticeTargetID = activePracticeTarget.id
        }
        PersonalizationEngine.updateProfile(
            &userProfile,
            phoneme: phoneme,
            audio: audio
        )
        UserProfileStore.save(userProfile)

        let summary = score.messages.map(\.text).joined(separator: " • ")
        let record = PracticeSessionRecord(
            targetPhoneme: phoneme.rawValue,
            targetSoundID: activePracticeTarget?.id ?? "",
            correctness: score.correctness,
            confidence: score.confidence,
            coachingSummary: summary,
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
