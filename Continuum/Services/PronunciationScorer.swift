import Foundation

/// Rule-based pronunciation scoring before ML is introduced.
enum PronunciationScorer {
    /// Scores one attempt and returns coaching feedback.
    /// - Parameters:
    ///   - phoneme: Target sound.
    ///   - visual: Aggregated face features.
    ///   - audio: Aggregated audio features.
    /// - Returns: Correctness score and coaching messages.
    static func score(phoneme: Phoneme, visual: VisualFeatures, audio: AudioFeatures) -> PronunciationScore {
        guard phoneme.isMVPSupported else {
            return PronunciationScore(
                correctness: 0,
                confidence: 0.2,
                messages: [
                    CoachingMessage(
                        text: "This phoneme needs more audio-focused coaching. Try /m/ or /p/ first.",
                        severity: .warning
                    )
                ]
            )
        }

        var messages: [CoachingMessage] = []
        var earnedPoints = 0
        let totalPoints = 100

        switch phoneme {
        case .m:
            earnedPoints += scoreLipClosure(visual: visual, messages: &messages, required: 0.35)
            earnedPoints += scoreJawOpening(visual: visual, messages: &messages, min: 0.02, max: 0.25)
            earnedPoints += scoreLowRounding(visual: visual, messages: &messages)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.4, max: 3.0)

        case .p:
            earnedPoints += scoreLipClosureBeforeRelease(visual: visual, messages: &messages)
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages)
            earnedPoints += scoreNoVoicing(audio: audio, messages: &messages)
            earnedPoints += scoreLowRounding(visual: visual, messages: &messages)

        case .b:
            earnedPoints += scoreLipClosureBeforeRelease(visual: visual, messages: &messages)
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true)
            earnedPoints += scoreLowRounding(visual: visual, messages: &messages)

        case .f, .v:
            earnedPoints += scoreLabiodentalPosture(visual: visual, messages: &messages)
            earnedPoints += scoreAirflow(audio: audio, messages: &messages)
            if phoneme == .f {
                earnedPoints += scoreNoVoicing(audio: audio, messages: &messages)
            } else {
                earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true)
            }
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.25, max: 3.0)

        case .u:
            earnedPoints += scoreVowelRounding(visual: visual, messages: &messages, required: 0.25)
            earnedPoints += scoreJawOpening(visual: visual, messages: &messages, min: 0.05, max: 0.35)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.35, max: 3.0)

        case .i:
            earnedPoints += scoreVowelSpread(visual: visual, messages: &messages)
            earnedPoints += scoreLowRounding(visual: visual, messages: &messages)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.35, max: 3.0)

        case .theta, .eth:
            break

        default:
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: phoneme.articulationKind != .stopUnvoiced && phoneme.articulationKind != .fricativeUnvoiced)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.2, max: 3.0)
        }

        let clampedScore = min(totalPoints, max(0, earnedPoints))
        let confidence = min(1.0, Double(visual.frameCount) / 30.0)

        if messages.isEmpty {
            messages.append(CoachingMessage(text: "Great articulation — keep practicing!", severity: .good))
        }

        return PronunciationScore(
            correctness: clampedScore,
            confidence: confidence,
            messages: messages
        )
    }

    /// Scores an attempt using audio features only (simulator-friendly demo mode).
    /// - Parameters:
    ///   - phoneme: Target sound.
    ///   - audio: Aggregated audio features.
    /// - Returns: Correctness score and coaching messages.
    static func scoreAudioOnly(phoneme: Phoneme, audio: AudioFeatures) -> PronunciationScore {
        guard phoneme.isAudioDemoSupported else {
            return PronunciationScore(
                correctness: 0,
                confidence: 0.2,
                messages: [CoachingMessage(text: "This phoneme is not supported yet.", severity: .warning)]
            )
        }

        var messages: [CoachingMessage] = []
        var earnedPoints = 0

        switch phoneme.articulationKind {
        case .stopUnvoiced:
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages, weight: 45)
            earnedPoints += scoreNoVoicing(audio: audio, messages: &messages, weight: 35)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.05, max: 1.5, weight: 20)

        case .stopVoiced:
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages, weight: 40)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 35)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.05, max: 1.5, weight: 25)

        case .nasal:
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 40)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.35, max: 3.0, weight: 35)
            earnedPoints += scoreSustainedEnergy(audio: audio, messages: &messages, weight: 25)

        case .fricativeUnvoiced:
            earnedPoints += scoreAirflow(audio: audio, messages: &messages, weight: 40)
            earnedPoints += scoreNoVoicing(audio: audio, messages: &messages, weight: 35)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.25, max: 3.0, weight: 25)

        case .fricativeVoiced:
            earnedPoints += scoreAirflow(audio: audio, messages: &messages, weight: 35)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 35)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.25, max: 3.0, weight: 30)

        case .affricateUnvoiced:
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages, weight: 35)
            earnedPoints += scoreFrication(audio: audio, messages: &messages, weight: 30)
            earnedPoints += scoreNoVoicing(audio: audio, messages: &messages, weight: 20)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.08, max: 2.0, weight: 15)

        case .affricateVoiced:
            earnedPoints += scoreBurstRelease(audio: audio, messages: &messages, weight: 30)
            earnedPoints += scoreFrication(audio: audio, messages: &messages, weight: 30)
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 25)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.08, max: 2.0, weight: 15)

        case .glide, .liquid:
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 40)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.3, max: 3.0, weight: 35)
            earnedPoints += scoreSustainedEnergy(audio: audio, messages: &messages, weight: 25)

        case .vowel:
            earnedPoints += scoreVoicing(audio: audio, messages: &messages, required: true, weight: 45)
            earnedPoints += scoreDuration(audio: audio, messages: &messages, min: 0.35, max: 3.0, weight: 35)
            earnedPoints += scoreSustainedEnergy(audio: audio, messages: &messages, weight: 20)
        }

        let clampedScore = min(100, max(0, earnedPoints))
        let confidence = min(1.0, audio.duration / 0.5)

        if messages.isEmpty {
            messages.append(CoachingMessage(text: "Great sound — keep practicing!", severity: .good))
        }

        return PronunciationScore(
            correctness: clampedScore,
            confidence: confidence,
            messages: messages,
            scoringMethod: .rules
        )
    }

    /// Rejects attempts with unusable audio before ML scoring is trusted.
    /// - Parameter audio: Aggregated audio features.
    /// - Returns: A critical coaching message when audio should be rejected.
    static func audioQualityFailure(for audio: AudioFeatures) -> CoachingMessage? {
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
        if audio.peakEnergy > 0.98 {
            return CoachingMessage(
                text: "Audio clipped — move slightly back from the microphone.",
                severity: .critical
            )
        }
        return nil
    }

    /// Scores an attempt with rules as a gate and embedding similarity as the primary scorer.
    /// - Parameters:
    ///   - phoneme: Target sound.
    ///   - audio: Aggregated audio features.
    ///   - chunks: Raw captured microphone chunks for embedding extraction.
    ///   - embeddingScorer: Bundled reference embedding scorer.
    /// - Returns: Final score from embeddings when available, otherwise rule-based scoring.
    @MainActor
    static func scoreAttempt(
        phoneme: Phoneme,
        audio: AudioFeatures,
        chunks: [AudioChunk],
        embeddingScorer: EmbeddingPronunciationScorer
    ) -> PronunciationScore {
        if let failure = audioQualityFailure(for: audio) {
            return PronunciationScore(
                correctness: 0,
                confidence: 0.1,
                messages: [failure],
                scoringMethod: .hybridFallback
            )
        }

        if let embeddingScore = embeddingScorer.score(phoneme: phoneme, chunks: chunks) {
            return embeddingScore
        }

        let ruleScore = scoreAudioOnly(phoneme: phoneme, audio: audio)
        var messages = ruleScore.messages
        messages.insert(
            CoachingMessage(
                text: "Using rule-based scoring — add PhonemeAudioEncoder.mlmodel and reference embeddings to enable ML.",
                severity: .warning
            ),
            at: 0
        )

        return PronunciationScore(
            correctness: ruleScore.correctness,
            confidence: ruleScore.confidence,
            messages: messages,
            scoringMethod: .rules
        )
    }

    /// Returns live coaching hints from current audio levels during recording.
    /// - Parameters:
    ///   - phoneme: Target sound.
    ///   - audio: Partial audio features captured so far.
    /// - Returns: Short live coaching messages.
    static func liveAudioHints(phoneme: Phoneme, audio: AudioFeatures) -> [CoachingMessage] {
        var hints: [CoachingMessage] = []

        if audio.duration < 0.1 {
            hints.append(CoachingMessage(text: "Start speaking…", severity: .warning))
            return hints
        }

        switch phoneme.articulationKind {
        case .stopUnvoiced, .fricativeUnvoiced, .affricateUnvoiced:
            if audio.voicedEnergyRatio < 0.2 {
                hints.append(CoachingMessage(text: "Good unvoiced airflow", severity: .good))
            } else {
                hints.append(CoachingMessage(text: "Reduce voice — airflow only", severity: .warning))
            }

        case .stopVoiced, .nasal, .fricativeVoiced, .affricateVoiced, .glide, .liquid, .vowel:
            if audio.voicedEnergyRatio > 0.2 {
                hints.append(CoachingMessage(text: "Voice detected", severity: .good))
            } else {
                hints.append(CoachingMessage(text: "Add voice — hum steadily", severity: .warning))
            }
        }

        if audio.rmsEnergy > 0.01 {
            hints.append(CoachingMessage(text: "Audio level looks good", severity: .good))
        } else {
            hints.append(CoachingMessage(text: "Speak louder or move closer to the mic", severity: .warning))
        }

        if phoneme.articulationKind == .stopUnvoiced || phoneme.articulationKind == .stopVoiced,
           audio.burstPeak > 0.03 {
            hints.append(CoachingMessage(text: "Sharp burst detected", severity: .good))
        }

        return hints
    }

    /// Returns live coaching hints from the latest face frame during recording.
    /// - Parameters:
    ///   - phoneme: Target sound.
    ///   - frame: Most recent tracked face frame.
    /// - Returns: Short live coaching messages.
    static func liveHints(phoneme: Phoneme, frame: FaceFrame) -> [CoachingMessage] {
        var hints: [CoachingMessage] = []

        switch phoneme {
        case .m, .p, .b:
            if frame.mouthClose < 0.3 {
                hints.append(CoachingMessage(text: "Close lips completely", severity: .warning))
            } else {
                hints.append(CoachingMessage(text: "Good lip closure", severity: .good))
            }
        case .f, .v:
            if frame.jawOpen < 0.05 {
                hints.append(CoachingMessage(text: "Open jaw slightly", severity: .warning))
            }
            if frame.mouthPucker > 0.35 {
                hints.append(CoachingMessage(text: "Relax lip rounding", severity: .warning))
            }
        case .u:
            if frame.mouthFunnel < 0.2 {
                hints.append(CoachingMessage(text: "Round lips more", severity: .warning))
            }
        case .i:
            if frame.mouthSmileLeft + frame.mouthSmileRight < 0.15 {
                hints.append(CoachingMessage(text: "Spread lips slightly", severity: .warning))
            }
        case .theta, .eth:
            hints.append(CoachingMessage(text: "Audio-only coaching for this sound", severity: .warning))

        default:
            hints.append(CoachingMessage(text: "Audio-only coaching for this sound", severity: .warning))
        }

        return hints
    }

    // MARK: - Rule helpers

    @discardableResult
    private static func scoreLipClosure(visual: VisualFeatures, messages: inout [CoachingMessage], required: Float) -> Int {
        if visual.maximumMouthClose >= required || visual.averageMouthClose >= required * 0.8 {
            messages.append(CoachingMessage(text: "Good lip closure", severity: .good))
            return 25
        }
        messages.append(CoachingMessage(
            text: "Close your lips completely before releasing the sound.",
            severity: .critical
        ))
        return 0
    }

    @discardableResult
    private static func scoreLipClosureBeforeRelease(visual: VisualFeatures, messages: inout [CoachingMessage]) -> Int {
        if visual.maximumMouthClose >= 0.3 {
            messages.append(CoachingMessage(text: "Lips closed before release", severity: .good))
            return 25
        }
        messages.append(CoachingMessage(
            text: "Build pressure with fully closed lips, then release.",
            severity: .critical
        ))
        return 5
    }

    @discardableResult
    private static func scoreJawOpening(
        visual: VisualFeatures,
        messages: inout [CoachingMessage],
        min: Float,
        max: Float
    ) -> Int {
        if visual.averageJawOpen >= min && visual.averageJawOpen <= max {
            messages.append(CoachingMessage(text: "Good jaw position", severity: .good))
            return 20
        }
        if visual.averageJawOpen < min {
            messages.append(CoachingMessage(text: "Open your mouth slightly wider.", severity: .warning))
        } else {
            messages.append(CoachingMessage(text: "Relax your jaw — opening is too wide.", severity: .warning))
        }
        return 8
    }

    @discardableResult
    private static func scoreLowRounding(visual: VisualFeatures, messages: inout [CoachingMessage]) -> Int {
        if visual.lipRounding <= 0.35 {
            messages.append(CoachingMessage(text: "Neutral lip shape", severity: .good))
            return 15
        }
        messages.append(CoachingMessage(text: "Round your lips less.", severity: .warning))
        return 5
    }

    @discardableResult
    private static func scoreVoicing(
        audio: AudioFeatures,
        messages: inout [CoachingMessage],
        required: Bool,
        weight: Int = 20
    ) -> Int {
        let voiced = audio.voicedEnergyRatio > 0.25
        if required && voiced {
            messages.append(CoachingMessage(text: "Good voicing", severity: .good))
            return weight
        }
        if required && !voiced {
            messages.append(CoachingMessage(
                text: "Add voice — feel vibration in your throat.",
                severity: .critical
            ))
            return 0
        }
        return weight / 2
    }

    @discardableResult
    private static func scoreNoVoicing(audio: AudioFeatures, messages: inout [CoachingMessage], weight: Int = 20) -> Int {
        if audio.voicedEnergyRatio < 0.2 {
            messages.append(CoachingMessage(text: "Good unvoiced airflow", severity: .good))
            return weight
        }
        messages.append(CoachingMessage(text: "Keep vocal cords relaxed — blow air only.", severity: .warning))
        return weight / 3
    }

    @discardableResult
    private static func scoreBurstRelease(audio: AudioFeatures, messages: inout [CoachingMessage], weight: Int = 25) -> Int {
        if audio.burstPeak > 0.04 {
            messages.append(CoachingMessage(text: "Sharp air release detected", severity: .good))
            return weight
        }
        messages.append(CoachingMessage(text: "Release the air more sharply.", severity: .warning))
        return weight / 3
    }

    @discardableResult
    private static func scoreAirflow(audio: AudioFeatures, messages: inout [CoachingMessage], weight: Int = 25) -> Int {
        if audio.rmsEnergy > 0.015 {
            messages.append(CoachingMessage(text: "Steady airflow", severity: .good))
            return weight
        }
        messages.append(CoachingMessage(text: "Blow more air through the sound.", severity: .warning))
        return weight / 3
    }

    @discardableResult
    private static func scoreDuration(
        audio: AudioFeatures,
        messages: inout [CoachingMessage],
        min: TimeInterval,
        max: TimeInterval,
        weight: Int = 20
    ) -> Int {
        if audio.duration >= min && audio.duration <= max {
            messages.append(CoachingMessage(text: "Good sound duration", severity: .good))
            return weight
        }
        if audio.duration < min {
            messages.append(CoachingMessage(text: "Hold the sound slightly longer.", severity: .warning))
        } else {
            messages.append(CoachingMessage(text: "Try a shorter, focused attempt.", severity: .warning))
        }
        return weight / 3
    }

    @discardableResult
    private static func scoreSustainedEnergy(audio: AudioFeatures, messages: inout [CoachingMessage], weight: Int) -> Int {
        if audio.rmsEnergy > 0.012 && audio.peakEnergy > 0.03 {
            messages.append(CoachingMessage(text: "Steady sound energy", severity: .good))
            return weight
        }
        messages.append(CoachingMessage(text: "Keep the sound steady and audible.", severity: .warning))
        return weight / 3
    }

    @discardableResult
    private static func scoreFrication(audio: AudioFeatures, messages: inout [CoachingMessage], weight: Int) -> Int {
        if audio.zeroCrossingRate > 0.08 && audio.rmsEnergy > 0.01 {
            messages.append(CoachingMessage(text: "Fricative noise detected", severity: .good))
            return weight
        }
        messages.append(CoachingMessage(text: "Add more turbulent airflow for the fricative.", severity: .warning))
        return weight / 3
    }

    @discardableResult
    private static func scoreLabiodentalPosture(visual: VisualFeatures, messages: inout [CoachingMessage]) -> Int {
        if visual.averageJawOpen >= 0.04 && visual.averageJawOpen <= 0.3 && visual.lipRounding < 0.4 {
            messages.append(CoachingMessage(text: "Good lip and jaw posture for /f/ or /v/", severity: .good))
            return 25
        }
        messages.append(CoachingMessage(
            text: "Rest upper teeth on lower lip with a slight jaw opening.",
            severity: .warning
        ))
        return 10
    }

    @discardableResult
    private static func scoreVowelRounding(visual: VisualFeatures, messages: inout [CoachingMessage], required: Float) -> Int {
        if visual.lipRounding >= required {
            messages.append(CoachingMessage(text: "Good lip rounding", severity: .good))
            return 25
        }
        messages.append(CoachingMessage(text: "Round your lips more.", severity: .warning))
        return 8
    }

    @discardableResult
    private static func scoreVowelSpread(visual: VisualFeatures, messages: inout [CoachingMessage]) -> Int {
        if visual.lipSpread >= 0.12 {
            messages.append(CoachingMessage(text: "Good lip spread", severity: .good))
            return 25
        }
        messages.append(CoachingMessage(text: "Spread lips slightly wider.", severity: .warning))
        return 8
    }
}

/// Updates recurring-issue counters from one scored attempt.
enum PersonalizationEngine {
    /// Applies attempt results to the user profile.
    /// - Parameters:
    ///   - profile: Profile to mutate.
    ///   - phoneme: Target phoneme.
    ///   - score: Scoring output.
    ///   - visual: Visual features.
    ///   - audio: Audio features.
    static func updateProfile(
        _ profile: inout UserPronunciationProfile,
        phoneme: Phoneme,
        score: PronunciationScore,
        visual: VisualFeatures,
        audio: AudioFeatures,
        audioOnly: Bool = false
    ) {
        if !audioOnly {
            if visual.maximumMouthClose < 0.25 && [.m, .p, .b].contains(phoneme) {
                profile.weakLipClosureCount += 1
            }
            if visual.lipRounding > 0.4 && phoneme != .u {
                profile.excessiveRoundingCount += 1
            }
        }
        if audio.rmsEnergy < 0.012 && [.f, .v].contains(phoneme) {
            profile.weakAirflowCount += 1
        }
        if audio.voicedEnergyRatio < 0.2 && [.m, .b, .v, .i, .u].contains(phoneme) {
            profile.weakVoicingCount += 1
        }
        if audio.duration < 0.35 {
            profile.shortDurationCount += 1
        }

        _ = score
    }
}
