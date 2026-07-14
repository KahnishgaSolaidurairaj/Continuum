//
//  ContinuumTests.swift
//  ContinuumTests
//

import Foundation
import Testing
@testable import Continuum

struct ContinuumTests {

    @Test func cosineSimilarityReturnsOneForIdenticalVectors() {
        let vector: [Float] = [0.1, 0.4, 0.8, 0.2]
        let similarity = CosineSimilarity.compare(vector, vector)
        #expect(similarity > 0.99)
    }

    @Test func bestSimilarityReturnsHighestPrototypeMatch() {
        let user: [Float] = [1, 0, 0]
        let prototypes: [[Float]] = [
            [0.6, 0.8, 0],
            [0.9, 0.1, 0],
            [0, 1, 0]
        ]

        let best = EmbeddingPronunciationScorer.bestSimilarity(
            userEmbedding: user,
            prototypes: prototypes
        )
        let expected = CosineSimilarity.compare(user, prototypes[1])

        #expect(best == expected)
        #expect(best > CosineSimilarity.compare(user, prototypes[0]))
    }

    @Test func activeSpeechRatioIsLowForNearSilentAudio() {
        let silentSamples = Array(repeating: Float(0.0001), count: 8_820)
        let chunk = AudioChunk(timestamp: 0, samples: silentSamples, sampleRate: 44_100)
        let ratio = FeatureExtractor.activeSpeechRatio(from: [chunk], threshold: 0.01)
        #expect(ratio < 0.12)
    }

    @Test func centerInFixedWindowPadsShortAudioInTheMiddle() {
        let centered = AudioSampleProcessor.centerInFixedWindow([0.5, -0.5], targetCount: 6)
        #expect(centered == [0, 0, 0.5, -0.5, 0, 0])
    }

    @Test func centerInFixedWindowCropsLongAudioFromTheMiddle() {
        let centered = AudioSampleProcessor.centerInFixedWindow(
            [1, 2, 3, 4, 5],
            targetCount: 3
        )
        #expect(centered == [2, 3, 4])
    }

    @Test func phonemeReferenceFileDecodesFromGeneratedJSON() throws {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Continuum/MLModels/PhonemeReferenceEmbeddings.json")

        let data = try Data(contentsOf: jsonURL)
        let decoded = try JSONDecoder().decode(PhonemeReferenceFile.self, from: data)

        #expect(decoded.version == 7)
        #expect(decoded.embeddingSize == 512)
        #expect(decoded.scoringWindowSeconds == 1.0)
        #expect((decoded.phonemes["b"]?.embeddings.count ?? 0) >= 3)
        #expect(decoded.phonemes["b"]?.prototypeEmbeddings.count == decoded.phonemes["b"]?.embeddings.count)
        #expect(decoded.phonemes["b"]?.activeSampleCount == 44_100)
        #expect(decoded.phonemes["b"]?.activeDurationSeconds == 1.0)
        #expect(decoded.phonemes["b"]?.referenceDurationSeconds == 1.0)
    }

}
