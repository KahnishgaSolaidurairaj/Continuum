import Foundation

/// Audio-quality checks shared by pronunciation scoring flows.
enum PronunciationScorer {
    private static let minimumActiveSpeechRatio: Float = 0.12
    private static let activeSpeechThreshold: Float = 0.01

    /// Rejects attempts with unusable audio before speech scoring is trusted.
    /// - Parameters:
    ///   - audio: Aggregated audio features.
    ///   - chunks: Raw captured microphone chunks used for saturation detection.
    ///   - voiceProcessingActive: Whether Apple voice processing shaped the capture.
    /// - Returns: A critical coaching message when audio should be rejected.
    static func audioQualityFailure(
        for audio: AudioFeatures,
        chunks: [AudioChunk] = [],
        voiceProcessingActive: Bool = false
    ) -> CoachingMessage? {
        if audio.duration < 0.08 {
            return CoachingMessage(
                text: "Too short — hold the sound a little longer.",
                severity: .critical
            )
        }
        if audio.rmsEnergy < 0.004 {
            return CoachingMessage(
                text: "No audio detected — speak louder or move closer to the mic.",
                severity: .critical
            )
        }
        let speechRatio = FeatureExtractor.activeSpeechRatio(
            from: chunks,
            threshold: activeSpeechThreshold
        )
        if speechRatio < minimumActiveSpeechRatio {
            return CoachingMessage(
                text: "No clear sound detected. Speak a little louder and try again.",
                severity: .critical
            )
        }
        if isClipped(audio: audio, chunks: chunks, voiceProcessingActive: voiceProcessingActive) {
            return CoachingMessage(
                text: "Audio clipped — move slightly back from the microphone.",
                severity: .critical
            )
        }
        return nil
    }

    /// Detects destructive clipping instead of normal voice-processing limiter peaks.
    private static func isClipped(
        audio: AudioFeatures,
        chunks: [AudioChunk],
        voiceProcessingActive: Bool
    ) -> Bool {
        let saturation = FeatureExtractor.saturationRatio(from: chunks)

        if voiceProcessingActive {
            return saturation > 0.08
        }

        return audio.peakEnergy > 0.98 || saturation > 0.03
    }
}

/// Updates recurring-issue counters from one scored attempt.
enum PersonalizationEngine {
    /// Applies attempt results to the user profile.
    /// - Parameters:
    ///   - profile: Profile to mutate.
    ///   - phoneme: Target phoneme.
    ///   - audio: Audio features from the attempt.
    static func updateProfile(
        _ profile: inout UserPronunciationProfile,
        phoneme: Phoneme,
        audio: AudioFeatures
    ) {
        if audio.rmsEnergy < 0.012 && [.f, .v].contains(phoneme) {
            profile.weakAirflowCount += 1
        }
        if audio.voicedEnergyRatio < 0.2 && [.m, .b, .v, .i, .u].contains(phoneme) {
            profile.weakVoicingCount += 1
        }
        if audio.duration < 0.35 {
            profile.shortDurationCount += 1
        }
    }
}
