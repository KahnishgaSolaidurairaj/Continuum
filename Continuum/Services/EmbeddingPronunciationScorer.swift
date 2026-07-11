import Accelerate
import AVFoundation
import CoreML
import Foundation

/// Scores pronunciation attempts by comparing audio embeddings to bundled TTS references.
@MainActor
final class EmbeddingPronunciationScorer {
    static let encoderResourceName = "PhonemeAudioEncoder"
    private static let minimumEncoderSamples = 8_000
    private static let similarityFloor: Float = 0.35
    private static let similarityCeiling: Float = 0.92
    private static let alternateSimilarityThreshold: Float = 0.55

    private let model: MLModel?
    private let references: PhonemeReferenceFile?

    private(set) var isReady = false

    init() {
        references = PhonemeReferenceCatalog.shared
        model = Self.loadEncoderModel()
        isReady = model != nil && references != nil
    }

    /// Scores one fixed-length attempt against the target phoneme reference.
    /// - Parameters:
    ///   - phoneme: The sound the user was asked to produce.
    ///   - chunks: Captured microphone chunks for the attempt.
    /// - Returns: Embedding-based score, or `nil` when assets are unavailable.
    func score(phoneme: Phoneme, chunks: [AudioChunk]) -> PronunciationScore? {
        guard
            isReady,
            let model,
            let references,
            let reference = references.phonemes[phoneme.modelLabel]
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

        let matchedSamples = AudioSampleProcessor.matchSampleCount(
            flattenedSamples,
            targetCount: reference.sampleCount
        )

        let encoderInput = AudioSampleProcessor.prepareEncoderInput(
            samples: matchedSamples,
            sourceSampleRate: firstChunk.sampleRate,
            referenceSampleCount: reference.sampleCount,
            encoderSampleRate: references.encoderSampleRate,
            minimumEncoderSamples: Self.minimumEncoderSamples
        )

        guard let userEmbedding = predictEmbedding(model: model, samples: encoderInput) else {
            return failureScore(
                text: "Could not extract an audio fingerprint. Try again."
            )
        }

        let referenceEmbedding = reference.embedding
        let similarity = CosineSimilarity.compare(userEmbedding, referenceEmbedding)
        let confidence = Double(similarity)
        let correctness = Self.similarityToPercent(similarity)
        var messages = coachingMessages(
            phoneme: phoneme,
            correctness: correctness,
            userEmbedding: userEmbedding,
            references: references,
            targetLabel: phoneme.modelLabel
        )

        messages.insert(
            CoachingMessage(text: "Scored with embedding similarity.", severity: .good),
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

    private func coachingMessages(
        phoneme: Phoneme,
        correctness: Int,
        userEmbedding: [Float],
        references: PhonemeReferenceFile,
        targetLabel: String
    ) -> [CoachingMessage] {
        var messages: [CoachingMessage] = []

        if correctness >= EmbeddingThreshold.strong {
            messages.append(CoachingMessage(
                text: "Strong match to /\(phoneme.symbol)/.",
                severity: .good
            ))
        } else if correctness >= EmbeddingThreshold.partial {
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

        if let alternateLabel = strongestAlternateLabel(
            userEmbedding: userEmbedding,
            references: references,
            excluding: targetLabel
        ) {
            messages.append(CoachingMessage(
                text: "Audio sounded closer to “\(alternateLabel)”.",
                severity: .warning
            ))
        }

        return messages
    }

    private func strongestAlternateLabel(
        userEmbedding: [Float],
        references: PhonemeReferenceFile,
        excluding targetLabel: String
    ) -> String? {
        let ranked = references.phonemes.compactMap { label, reference -> (String, Float)? in
            guard label != targetLabel else { return nil }
            let similarity = CosineSimilarity.compare(userEmbedding, reference.embedding)
            return (label, similarity)
        }
        .sorted { $0.1 > $1.1 }

        guard
            let strongest = ranked.first,
            strongest.1 >= Self.alternateSimilarityThreshold
        else {
            return nil
        }
        return strongest.0
    }

    private func failureScore(text: String) -> PronunciationScore {
        PronunciationScore(
            correctness: 0,
            confidence: 0,
            messages: [CoachingMessage(text: text, severity: .warning)],
            scoringMethod: .embeddingSimilarity
        )
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

    /// Resamples and sizes one clip for Audio Feature Print inference.
    /// - Parameters:
    ///   - samples: Source PCM samples.
    ///   - sourceSampleRate: Sample rate of the captured audio.
    ///   - referenceSampleCount: Sample count of the bundled reference clip.
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
