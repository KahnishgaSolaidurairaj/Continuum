import Accelerate
import AVFoundation
import CoreML
import Foundation

/// Scores pronunciation attempts by comparing trimmed audio embeddings to bundled references.
@MainActor
final class EmbeddingPronunciationScorer {
    static let encoderResourceName = "PhonemeAudioEncoder"
    private static let minimumEncoderSamples = 8_000
    private static let similarityFloor: Float = 0.45
    private static let similarityCeiling: Float = 0.92
    private static let minimumAcceptableSimilarity: Float = 0.58
    private static let trimThreshold: Float = 0.01
    private static let targetPeak: Float = 0.9
    private static let minimumActiveSamples = 256
    private static let minimumTrimmedRMS: Float = 0.008
    private static let minimumTrimmedDurationSeconds: TimeInterval = 0.15
    private static let scoringWindowSeconds: TimeInterval = 1.0

    private let model: MLModel?
    private let references: PhonemeReferenceFile?

    private(set) var isReady = false

    init() {
        references = PhonemeReferenceCatalog.shared
        model = Self.loadEncoderModel()
        isReady = model != nil && references != nil
    }

    /// Scores one fixed-length attempt against the target practice sound reference.
    /// - Parameters:
    ///   - soundID: The practice sound identifier.
    ///   - phoneme: Linked phoneme used for coaching copy.
    ///   - chunks: Captured microphone chunks for the attempt.
    /// - Returns: Embedding-based score, or `nil` when assets are unavailable.
    func score(soundID: String, phoneme: Phoneme, chunks: [AudioChunk]) -> PronunciationScore? {
        guard
            isReady,
            let model,
            let references,
            let reference = references.phonemes[soundID]
        else {
            return nil
        }

        guard let firstChunk = chunks.first, !chunks.isEmpty else {
            return failureScore(
                text: "Could not analyze the recording. Try again with a clearer sound."
            )
        }

        let flattenedSamples = chunks.flatMap(\.samples)
        guard !flattenedSamples.isEmpty else {
            return failureScore(
                text: "Could not analyze the recording. Try again with a clearer sound."
            )
        }

        let trimmedSamples = AudioSampleProcessor.trimSilence(
            flattenedSamples,
            sampleRate: firstChunk.sampleRate,
            threshold: Self.trimThreshold
        )
        guard trimmedSamples.count >= Self.minimumActiveSamples else {
            return failureScore(
                text: "No clear sound detected. Speak a little louder and try again."
            )
        }

        let minimumTrimmedSamples = Int(firstChunk.sampleRate * Self.minimumTrimmedDurationSeconds)
        guard trimmedSamples.count >= minimumTrimmedSamples else {
            return failureScore(
                text: "Hold the sound a little longer and try again."
            )
        }

        let trimmedRMS = AudioSampleProcessor.rootMeanSquare(trimmedSamples)
        guard trimmedRMS >= Self.minimumTrimmedRMS else {
            return failureScore(
                text: "No clear sound detected. Speak a little louder and try again."
            )
        }

        let normalizedSamples = AudioSampleProcessor.normalizePeak(
            trimmedSamples,
            targetPeak: Self.targetPeak
        )

        let encoderInput = AudioSampleProcessor.prepareScoringEncoderInput(
            samples: normalizedSamples,
            sourceSampleRate: firstChunk.sampleRate,
            encoderSampleRate: references.encoderSampleRate,
            windowSeconds: Self.scoringWindowSeconds,
            minimumEncoderSamples: Self.minimumEncoderSamples
        )

        guard let userEmbedding = predictEmbedding(model: model, samples: encoderInput) else {
            return failureScore(
                text: "Could not extract an audio fingerprint. Try again."
            )
        }

        let targetSimilarity = Self.bestSimilarity(
            userEmbedding: userEmbedding,
            prototypes: reference.prototypeEmbeddings
        )
        guard targetSimilarity >= Self.minimumAcceptableSimilarity else {
            return failureScore(
                text: "Low match to /\(phoneme.symbol)/ — try matching the Flashcard sound.",
                severity: .critical
            )
        }

        let confidence = Double(targetSimilarity)
        let correctness = Self.displayScore(targetSimilarity: targetSimilarity)
        var messages = coachingMessages(
            phoneme: phoneme,
            correctness: correctness
        )

        messages.insert(
            CoachingMessage(text: "Compared to the Flashcard reference sound.", severity: .good),
            at: 0
        )

        return PronunciationScore(
            correctness: correctness,
            confidence: confidence,
            messages: messages,
            scoringMethod: .embeddingSimilarity
        )
    }

    /// Runs the bundled encoder on one prepared audio buffer.
    /// - Parameters:
    ///   - model: Audio Feature Print encoder model.
    ///   - samples: Mono PCM samples at the encoder sample rate.
    /// - Returns: A 512-dimensional embedding, or `nil` on failure.
    private func predictEmbedding(model: MLModel, samples: [Float]) -> [Float]? {
        guard let array = try? MLMultiArray(
            shape: [NSNumber(value: samples.count)],
            dataType: .float32
        ) else {
            return nil
        }

        for index in 0..<samples.count {
            array[index] = NSNumber(value: samples[index])
        }

        guard
            let provider = try? MLDictionaryFeatureProvider(dictionary: ["audioSamples": array]),
            let prediction = try? model.prediction(from: provider),
            let featureValue = prediction.featureValue(for: "features"),
            let multiArray = featureValue.multiArrayValue
        else {
            return nil
        }

        var embedding = [Float]()
        embedding.reserveCapacity(multiArray.count)
        for index in 0..<multiArray.count {
            embedding.append(multiArray[index].floatValue)
        }
        return embedding
    }

    /// Returns the highest cosine similarity between a user embedding and prototype vectors.
    /// - Parameters:
    ///   - userEmbedding: Embedding extracted from the user's recording.
    ///   - prototypes: Bundled reference embeddings for one practice sound.
    /// - Returns: Maximum similarity across all prototypes.
    nonisolated static func bestSimilarity(userEmbedding: [Float], prototypes: [[Float]]) -> Float {
        prototypes
            .map { CosineSimilarity.compare(userEmbedding, $0) }
            .max() ?? 0
    }

    private func coachingMessages(
        phoneme: Phoneme,
        correctness: Int
    ) -> [CoachingMessage] {
        if correctness >= EmbeddingThreshold.strong {
            return [CoachingMessage(
                text: "Strong match to /\(phoneme.symbol)/.",
                severity: .good
            )]
        }
        if correctness >= EmbeddingThreshold.partial {
            return [CoachingMessage(
                text: "Partial match — try a clearer /\(phoneme.symbol)/.",
                severity: .warning
            )]
        }
        return [CoachingMessage(
            text: "Low match to /\(phoneme.symbol)/.",
            severity: .critical
        )]
    }

    private func failureScore(
        text: String,
        severity: CoachingSeverity = .warning
    ) -> PronunciationScore {
        PronunciationScore(
            correctness: 0,
            confidence: 0,
            messages: [CoachingMessage(text: text, severity: severity)],
            scoringMethod: .embeddingSimilarity
        )
    }

    private static func displayScore(targetSimilarity: Float) -> Int {
        similarityToPercent(targetSimilarity)
    }

    private static func similarityToPercent(_ similarity: Float) -> Int {
        let clamped = min(similarityCeiling, max(similarityFloor, similarity))
        let normalized = (clamped - similarityFloor) / (similarityCeiling - similarityFloor)
        return Int(round(normalized * 100))
    }

    private static func loadEncoderModel() -> MLModel? {
        let url: URL?
        if let compiledURL = Bundle.main.url(
            forResource: encoderResourceName,
            withExtension: "mlmodelc"
        ) {
            url = compiledURL
        } else {
            url = Bundle.main.url(
                forResource: encoderResourceName,
                withExtension: "mlmodel"
            )
        }

        guard let url else { return nil }
        return try? MLModel(contentsOf: url)
    }
}

/// Provisional score cutoffs for embedding coaching messages.
private enum EmbeddingThreshold {
    static let strong = 60
    static let partial = 35
}

/// Vector math helpers for embedding comparison.
enum CosineSimilarity {
    /// Returns cosine similarity for two equal-length vectors.
    /// - Parameters:
    ///   - left: First embedding vector.
    ///   - right: Second embedding vector.
    /// - Returns: Similarity in the range `0...1` for normalized feature prints.
    static func compare(_ left: [Float], _ right: [Float]) -> Float {
        guard left.count == right.count, !left.isEmpty else { return 0 }

        var dotProduct: Float = 0
        var leftSumSquares: Float = 0
        var rightSumSquares: Float = 0
        let length = vDSP_Length(left.count)

        vDSP_dotpr(left, 1, right, 1, &dotProduct, length)
        vDSP_svesq(left, 1, &leftSumSquares, length)
        vDSP_svesq(right, 1, &rightSumSquares, length)

        let denominator = sqrt(leftSumSquares) * sqrt(rightSumSquares)
        guard denominator > 1e-8 else { return 0 }
        return dotProduct / denominator
    }
}

/// Normalizes captured microphone audio to the encoder's expected format.
enum AudioSampleProcessor {
    /// Returns the root-mean-square energy for one PCM buffer.
    /// - Parameter samples: Source PCM samples.
    /// - Returns: RMS amplitude.
    static func rootMeanSquare(_ samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        let sumSquares = samples.reduce(Float.zero) { partial, sample in
            partial + sample * sample
        }
        return sqrt(sumSquares / Float(samples.count))
    }

    /// Trims leading and trailing silence below an RMS threshold.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - sampleRate: Sample rate of the captured audio.
    ///   - threshold: RMS threshold used to detect active audio.
    /// - Returns: Samples containing only the active region.
    static func trimSilence(
        _ samples: [Float],
        sampleRate: Double,
        threshold: Float = 0.01
    ) -> [Float] {
        let window = max(256, Int(sampleRate * 0.01))
        guard samples.count >= window else { return samples }

        func windowRMS(start: Int) -> Float {
            let end = min(start + window, samples.count)
            let chunk = samples[start..<end]
            let sumSquares = chunk.reduce(Float.zero) { partial, sample in
                partial + sample * sample
            }
            return sqrt(sumSquares / Float(chunk.count))
        }

        let step = max(1, window / 2)
        let activeStarts = stride(from: 0, to: samples.count - window, by: step).filter { index in
            windowRMS(start: index) >= threshold
        }

        guard
            let first = activeStarts.first,
            let last = activeStarts.last
        else {
            return samples
        }

        return Array(samples[first..<min(last + window, samples.count)])
    }

    /// Peak-normalizes audio to a target level.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - targetPeak: Desired peak amplitude.
    /// - Returns: Peak-normalized samples.
    static func normalizePeak(_ samples: [Float], targetPeak: Float = 0.9) -> [Float] {
        guard let peak = samples.map({ abs($0) }).max(), peak > 1e-6 else {
            return samples
        }
        let scale = targetPeak / peak
        return samples.map { $0 * scale }
    }

    /// Trims or zero-pads one clip to an exact sample count.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - targetCount: Desired sample count.
    /// - Returns: A clip with exactly `targetCount` samples.
    static func matchSampleCount(_ samples: [Float], targetCount: Int) -> [Float] {
        guard targetCount > 0 else { return samples }
        if samples.count == targetCount {
            return samples
        }
        if samples.count > targetCount {
            return Array(samples.prefix(targetCount))
        }
        return samples + Array(repeating: 0, count: targetCount - samples.count)
    }

    /// Centers active audio in a fixed-length window with silence padding on both sides.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - targetCount: Exact number of samples in the output window.
    /// - Returns: A clip with the original audio centered in silence.
    static func centerInFixedWindow(_ samples: [Float], targetCount: Int) -> [Float] {
        guard targetCount > 0 else { return samples }
        if samples.count == targetCount {
            return samples
        }
        if samples.count > targetCount {
            let start = (samples.count - targetCount) / 2
            return Array(samples[start..<(start + targetCount)])
        }

        let padding = targetCount - samples.count
        let leading = padding / 2
        let trailing = padding - leading
        return Array(repeating: 0, count: leading)
            + samples
            + Array(repeating: 0, count: trailing)
    }

    /// Builds a fixed-length scoring clip for Test: centered 1s window, then encoder rate.
    /// - Parameters:
    ///   - samples: Trimmed and peak-normalized PCM samples.
    ///   - sourceSampleRate: Sample rate of the captured audio.
    ///   - encoderSampleRate: Sample rate expected by the encoder.
    ///   - windowSeconds: Fixed scoring window duration.
    ///   - minimumEncoderSamples: Minimum valid encoder input length.
    /// - Returns: Mono PCM samples ready for `MLModel` prediction.
    static func prepareScoringEncoderInput(
        samples: [Float],
        sourceSampleRate: Double,
        encoderSampleRate: Double,
        windowSeconds: TimeInterval,
        minimumEncoderSamples: Int
    ) -> [Float] {
        let sourceWindowCount = Int(round(sourceSampleRate * windowSeconds))
        let centered = centerInFixedWindow(samples, targetCount: sourceWindowCount)
        let resampled = resample(
            centered,
            sourceSampleRate: sourceSampleRate,
            targetSampleRate: encoderSampleRate
        )
        let encoderWindowCount = max(
            minimumEncoderSamples,
            Int(round(encoderSampleRate * windowSeconds))
        )
        return centerInFixedWindow(resampled, targetCount: encoderWindowCount)
    }

    /// Resamples and sizes one clip for Audio Feature Print inference.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - sourceSampleRate: Sample rate of the captured audio.
    ///   - referenceSampleCount: Active sample count of the bundled reference clip.
    ///   - encoderSampleRate: Sample rate expected by the encoder.
    ///   - minimumEncoderSamples: Minimum valid encoder input length.
    /// - Returns: Mono PCM samples ready for `MLModel` prediction.
    static func prepareEncoderInput(
        samples: [Float],
        sourceSampleRate: Double,
        referenceSampleCount: Int,
        encoderSampleRate: Double,
        minimumEncoderSamples: Int
    ) -> [Float] {
        let resampled = resample(
            samples,
            sourceSampleRate: sourceSampleRate,
            targetSampleRate: encoderSampleRate
        )

        let scaledCount = Int(
            round(Double(referenceSampleCount) * encoderSampleRate / sourceSampleRate)
        )
        let targetCount = max(minimumEncoderSamples, scaledCount)
        return matchSampleCount(resampled, targetCount: targetCount)
    }

    /// Resamples mono PCM audio using `AVAudioConverter` when available.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - sourceSampleRate: Original sample rate.
    ///   - targetSampleRate: Desired sample rate.
    /// - Returns: Resampled mono samples.
    static func resample(
        _ samples: [Float],
        sourceSampleRate: Double,
        targetSampleRate: Double
    ) -> [Float] {
        guard
            !samples.isEmpty,
            sourceSampleRate > 0,
            targetSampleRate > 0,
            sourceSampleRate != targetSampleRate,
            let sourceFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sourceSampleRate,
                channels: 1,
                interleaved: false
            ),
            let targetFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: targetSampleRate,
                channels: 1,
                interleaved: false
            ),
            let converter = AVAudioConverter(from: sourceFormat, to: targetFormat)
        else {
            return samples
        }

        let frameCapacity = AVAudioFrameCount(
            ceil(Double(samples.count) * targetSampleRate / sourceSampleRate)
        )
        guard
            let sourceBuffer = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: AVAudioFrameCount(samples.count)
            ),
            let targetBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFormat,
                frameCapacity: max(frameCapacity, 1)
            ),
            let sourceChannel = sourceBuffer.floatChannelData?[0]
        else {
            return samples
        }

        sourceBuffer.frameLength = AVAudioFrameCount(samples.count)
        for index in 0..<samples.count {
            sourceChannel[index] = samples[index]
        }

        var error: NSError?
        let status = converter.convert(to: targetBuffer, error: &error) { _, inputStatus in
            inputStatus.pointee = .haveData
            return sourceBuffer
        }

        guard status != .error, let targetChannel = targetBuffer.floatChannelData?[0] else {
            return samples
        }

        return Array(UnsafeBufferPointer(
            start: targetChannel,
            count: Int(targetBuffer.frameLength)
        ))
    }
}
