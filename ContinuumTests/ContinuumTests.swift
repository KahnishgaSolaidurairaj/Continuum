//
//  ContinuumTests.swift
//  ContinuumTests
//

import Testing
@testable import Continuum

struct ContinuumTests {

    @Test func cosineSimilarityReturnsOneForIdenticalVectors() {
        let vector: [Float] = [0.1, 0.4, 0.8, 0.2]
        let similarity = CosineSimilarity.compare(vector, vector)
        #expect(similarity > 0.99)
    }

    @Test func phonemeReferenceFileDecodesFromGeneratedJSON() throws {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Continuum/MLModels/PhonemeReferenceEmbeddings.json")

        let data = try Data(contentsOf: jsonURL)
        let decoded = try JSONDecoder().decode(PhonemeReferenceFile.self, from: data)

        #expect(decoded.version == 2)
        #expect(decoded.embeddingSize == 512)
        #expect(decoded.phonemes["m"]?.embedding.count == 512)
        #expect((decoded.phonemes["m"]?.referenceDurationSeconds ?? 0) > 0)
    }

}
