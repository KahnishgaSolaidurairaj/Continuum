import AVFoundation
import CoreML
import Foundation
import SoundAnalysis

/// Scores pronunciation attempts using a Create ML sound classifier on live mic audio.
@MainActor
final class MLPronunciationScorer: NSObject, SNResultsObserving {
    static let modelResourceName = "PhonemeClassifier"

    /// Windows whose `noise` confidence is at or above this are treated as silence
    /// and excluded when averaging sustained sounds.
    private static let noiseGateThreshold: Float = 0.5

    /// Minimum average confidence for a competing label to be worth mentioning.
    private static let alternateLabelThreshold: Float = 0.25

    private var analyzer: SNAudioStreamAnalyzer?
    private var streamPosition: AVAudioFramePosition = 0

    /// One entry per analysis window, each mapping every class label to its confidence.
    /// Keeping results grouped by window lets us compare the target against `noise`
    /// within the same moment instead of across the whole recording.
    private var windowResults: [[String: Float]] = []

    private(set) var isReady = false

    /// Prepares SoundAnalysis to classify audio using the bundled Core ML model.
    /// - Parameter format: Input format from the active microphone tap.
    func prepare(format: AVAudioFormat) throws {
        reset()

        guard let modelURL = Self.locateModelURL() else {
            isReady = false
            return
        }

        let model = try MLModel(contentsOf: modelURL)
        let request = try SNClassifySoundRequest(mlModel: model)
        request.windowDuration = CMTimeMake(value: 1, timescale: 2)

        let analyzer = SNAudioStreamAnalyzer(format: format)
        try analyzer.add(request, withObserver: self)
        self.analyzer = analyzer
        isReady = true
    }

    /// Clears accumulated predictions for a new recording.
    func reset() {
        analyzer = nil
        streamPosition = 0
        windowResults = []
        isReady = false
    }

    /// Feeds one microphone buffer into the sound classifier.
    /// - Parameter buffer: PCM buffer from `AudioCaptureService`.
    func process(buffer: AVAudioPCMBuffer) {
        guard isReady, let analyzer else { return }
        analyzer.analyze(buffer, atAudioFramePosition: streamPosition)
        streamPosition += AVAudioFramePosition(buffer.frameLength)
    }

    /// Builds a score by aggregating per-window confidences for the target sound.
    ///
    /// Sustained sounds are averaged over the windows where the user was actually
    /// speaking, while transient bursts use their strongest windows. This rewards
    /// consistency instead of a single lucky peak.
    /// - Parameter phoneme: The sound the user was asked to produce.
    /// - Returns: ML-based score, or `nil` when the model is unavailable.
    func score(phoneme: Phoneme) -> PronunciationScore? {
        guard isReady else { return nil }

        let targetLabel = phoneme.modelLabel
        guard !windowResults.isEmpty else {
            return PronunciationScore(
                correctness: 0,
                confidence: 0,
                messages: [
                    CoachingMessage(
                        text: "Could not classify the recording. Try again with a clearer sound.",
                        severity: .warning
                    )
                ],
                scoringMethod: .machineLearning
            )
        }

        let accuracy = aggregateAccuracy(for: phoneme, targetLabel: targetLabel)
        let confidence = Double(accuracy)
        let correctness = Int(round(confidence * 100))
        var messages = coachingMessages(
            phoneme: phoneme,
            correctness: correctness,
            targetLabel: targetLabel
        )

        messages.insert(
            CoachingMessage(text: "Scored with on-device ML model.", severity: .good),
            at: 0
        )

        return PronunciationScore(
            correctness: correctness,
            confidence: confidence,
            messages: messages,
            scoringMethod: .machineLearning
        )
    }

    /// Aggregates per-window target confidences into a single accuracy value.
    /// - Parameters:
    ///   - phoneme: The target sound, which determines the aggregation strategy.
    ///   - targetLabel: The model label for the target sound.
    /// - Returns: Mean accuracy in the range `0...1`.
    private func aggregateAccuracy(for phoneme: Phoneme, targetLabel: String) -> Float {
        switch phoneme.mlAggregation {
        case .sustained:
            let activeWindows = speechActiveWindows()
            let targetConfidences = activeWindows.map { $0[targetLabel] ?? 0 }
            return mean(of: targetConfidences)

        case .transient:
            let sortedConfidences = windowResults
                .map { $0[targetLabel] ?? 0 }
                .sorted(by: >)
            let strongestWindows = Array(sortedConfidences.prefix(2))
            return mean(of: strongestWindows)
        }
    }

    /// Returns windows where speech was present, using the model's `noise` label.
    ///
    /// Falls back to all windows when every window looks like silence so the mean
    /// is never divided by zero.
    /// - Returns: Windows considered speech-active.
    private func speechActiveWindows() -> [[String: Float]] {
        let activeWindows = windowResults.filter { window in
            (window[Phoneme.noiseModelLabel] ?? 0) < Self.noiseGateThreshold
        }
        return activeWindows.isEmpty ? windowResults : activeWindows
    }

    /// Computes the arithmetic mean, returning `0` for an empty input.
    /// - Parameter values: Confidence values to average.
    /// - Returns: Mean value, or `0` when there are no values.
    private func mean(of values: [Float]) -> Float {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Float(values.count)
    }

    nonisolated func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let classification = result as? SNClassificationResult else { return }

        var window: [String: Float] = [:]
        for classificationEntry in classification.classifications {
            window[classificationEntry.identifier] = Float(classificationEntry.confidence)
        }

        Task { @MainActor in
            windowResults.append(window)
        }
    }

    nonisolated func request(_ request: SNRequest, didFailWithError error: Error) {
        Task { @MainActor in
            isReady = false
        }
    }

    private static func locateModelURL() -> URL? {
        if let compiledURL = Bundle.main.url(
            forResource: modelResourceName,
            withExtension: "mlmodelc"
        ) {
            return compiledURL
        }

        return Bundle.main.url(
            forResource: modelResourceName,
            withExtension: "mlmodel"
        )
    }

    private func coachingMessages(
        phoneme: Phoneme,
        correctness: Int,
        targetLabel: String
    ) -> [CoachingMessage] {
        var messages: [CoachingMessage] = []

        if correctness >= MLThreshold.strong {
            messages.append(CoachingMessage(
                text: "Strong match to /\(phoneme.symbol)/.",
                severity: .good
            ))
        } else if correctness >= MLThreshold.partial {
            messages.append(CoachingMessage(
                text: "Partial match — try a clearer /\(phoneme.symbol)/.",
                severity: .warning
            ))
        } else {
            messages.append(CoachingMessage(
                text: "Low match to /\(phoneme.symbol)/.",
                severity: .critical
            ))
        }

        if let alternateLabel = strongestAlternateLabel(excluding: targetLabel) {
            messages.append(CoachingMessage(
                text: "Audio sounded closer to “\(alternateLabel)”.",
                severity: .warning
            ))
        }

        return messages
    }

    private func strongestAlternateLabel(excluding targetLabel: String) -> String? {
        let activeWindows = speechActiveWindows()
        guard !activeWindows.isEmpty else { return nil }

        var totals: [String: Float] = [:]
        for window in activeWindows {
            for (label, confidence) in window where label != targetLabel {
                totals[label, default: 0] += confidence
            }
        }

        let averaged = totals.map { label, sum in
            (label, sum / Float(activeWindows.count))
        }

        guard
            let strongest = averaged.max(by: { $0.1 < $1.1 }),
            strongest.1 >= Self.alternateLabelThreshold
        else {
            return nil
        }
        return strongest.0
    }
}

/// Provisional score cutoffs for ML coaching messages.
///
/// Mean-over-active scores run lower than the previous peak-based scores, so these
/// are intentionally lower than the old `75 / 45`. Final values require validation
/// against a trained model and real device recordings.
private enum MLThreshold {
    static let strong = 60
    static let partial = 35
}
