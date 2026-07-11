import Foundation

/// One bundled reference clip and its precomputed embedding.
struct PhonemeReference: Codable, Sendable {
    let embedding: [Float]
    let referenceDurationSeconds: Double
    let referenceAudioFile: String
    let sampleRate: Double
    let sampleCount: Int
    let aggregation: String
}

/// Decoded contents of `PhonemeReferenceEmbeddings.json`.
struct PhonemeReferenceFile: Codable, Sendable {
    let version: Int
    let embeddingSize: Int
    let voice: String
    let encoderSampleRate: Double
    let phonemes: [String: PhonemeReference]
}

/// Loads bundled phoneme reference metadata used for timed recording and scoring.
enum PhonemeReferenceCatalog {
    private static let resourceName = "PhonemeReferenceEmbeddings"

    /// Shared catalog loaded from the app bundle.
    static let shared: PhonemeReferenceFile? = loadFromBundle()

    /// Returns the reference entry for a target phoneme.
    /// - Parameter phoneme: The sound being practiced.
    /// - Returns: Reference metadata, or `nil` when assets are missing.
    static func reference(for phoneme: Phoneme) -> PhonemeReference? {
        shared?.phonemes[phoneme.modelLabel]
    }

    /// Returns the forced recording duration for a phoneme.
    /// - Parameter phoneme: The sound being practiced.
    /// - Returns: Duration in seconds, or a short default when metadata is unavailable.
    static func recordingDuration(for phoneme: Phoneme) -> TimeInterval {
        reference(for: phoneme)?.referenceDurationSeconds ?? 0.8
    }

    private static func loadFromBundle() -> PhonemeReferenceFile? {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "json"
        ) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(PhonemeReferenceFile.self, from: data)
        } catch {
            return nil
        }
    }
}
