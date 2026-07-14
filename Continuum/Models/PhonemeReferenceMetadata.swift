import Foundation

/// One bundled reference clip and its precomputed embedding.
struct PhonemeReference: Codable, Sendable {
    let embedding: [Float]
    let embeddings: [[Float]]
    let prototypeCount: Int?
    let referenceDurationSeconds: Double
    let referenceAudioFile: String
    let sampleRate: Double
    let sampleCount: Int
    let activeSampleCount: Int
    let activeSampleCounts: [Int]
    let activeDurationSeconds: Double?
    let aggregation: String

    /// All prototype vectors available for max-similarity scoring.
    var prototypeEmbeddings: [[Float]] {
        if !embeddings.isEmpty {
            return embeddings
        }
        return [embedding]
    }

    /// Median active sample count across prototypes for encoder alignment.
    var medianActiveSampleCount: Int {
        let counts = activeSampleCounts.isEmpty ? [activeSampleCount] : activeSampleCounts
        let sorted = counts.sorted()
        guard !sorted.isEmpty else { return activeSampleCount }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    enum CodingKeys: String, CodingKey {
        case embedding
        case embeddings
        case prototypeCount
        case referenceDurationSeconds
        case referenceAudioFile
        case sampleRate
        case sampleCount
        case activeSampleCount
        case activeSampleCounts
        case activeDurationSeconds
        case aggregation
    }

    init(
        embedding: [Float],
        embeddings: [[Float]],
        prototypeCount: Int?,
        referenceDurationSeconds: Double,
        referenceAudioFile: String,
        sampleRate: Double,
        sampleCount: Int,
        activeSampleCount: Int,
        activeSampleCounts: [Int],
        activeDurationSeconds: Double?,
        aggregation: String
    ) {
        self.embedding = embedding
        self.embeddings = embeddings
        self.prototypeCount = prototypeCount
        self.referenceDurationSeconds = referenceDurationSeconds
        self.referenceAudioFile = referenceAudioFile
        self.sampleRate = sampleRate
        self.sampleCount = sampleCount
        self.activeSampleCount = activeSampleCount
        self.activeSampleCounts = activeSampleCounts
        self.activeDurationSeconds = activeDurationSeconds
        self.aggregation = aggregation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedEmbedding = try container.decodeIfPresent([Float].self, forKey: .embedding) ?? []
        let decodedEmbeddings = try container.decodeIfPresent([[Float]].self, forKey: .embeddings) ?? []
        let resolvedEmbeddings: [[Float]]
        let resolvedEmbedding: [Float]

        if decodedEmbeddings.isEmpty, !decodedEmbedding.isEmpty {
            resolvedEmbeddings = [decodedEmbedding]
            resolvedEmbedding = decodedEmbedding
        } else if !decodedEmbeddings.isEmpty {
            resolvedEmbeddings = decodedEmbeddings
            resolvedEmbedding = decodedEmbedding.isEmpty ? (decodedEmbeddings.first ?? []) : decodedEmbedding
        } else {
            resolvedEmbeddings = []
            resolvedEmbedding = []
        }

        embedding = resolvedEmbedding
        embeddings = resolvedEmbeddings
        prototypeCount = try container.decodeIfPresent(Int.self, forKey: .prototypeCount)
        referenceDurationSeconds = try container.decode(Double.self, forKey: .referenceDurationSeconds)
        referenceAudioFile = try container.decode(String.self, forKey: .referenceAudioFile)
        sampleRate = try container.decode(Double.self, forKey: .sampleRate)
        sampleCount = try container.decode(Int.self, forKey: .sampleCount)
        activeSampleCount = try container.decode(Int.self, forKey: .activeSampleCount)
        let decodedActiveCounts = try container.decodeIfPresent([Int].self, forKey: .activeSampleCounts) ?? []
        activeSampleCounts = decodedActiveCounts.isEmpty ? [activeSampleCount] : decodedActiveCounts
        activeDurationSeconds = try container.decodeIfPresent(Double.self, forKey: .activeDurationSeconds)
        aggregation = try container.decode(String.self, forKey: .aggregation)
    }
}

/// Decoded contents of `PhonemeReferenceEmbeddings.json`.
struct PhonemeReferenceFile: Codable, Sendable {
    let version: Int
    let embeddingSize: Int
    let voice: String
    let encoderSampleRate: Double
    let scoringWindowSeconds: Double?
    let targetDurationSeconds: Double?
    let phonemes: [String: PhonemeReference]
}

/// Loads bundled phoneme reference metadata used for timed recording and scoring.
enum PhonemeReferenceCatalog {
    private static let resourceName = "PhonemeReferenceEmbeddings"

    /// Shared catalog loaded from the app bundle.
    static let shared: PhonemeReferenceFile? = loadFromBundle()

    /// Fixed recording duration for all practice sounds.
    static let targetRecordingDuration: TimeInterval = 1.0

    /// Returns the reference entry for a practice sound ID.
    /// - Parameter soundID: The practice sound identifier.
    /// - Returns: Reference metadata, or `nil` when assets are missing.
    static func reference(forSoundID soundID: String) -> PhonemeReference? {
        shared?.phonemes[soundID]
    }

    /// Returns the forced recording duration for a practice sound.
    /// - Parameter soundID: The practice sound identifier.
    /// - Returns: Duration in seconds, aligned with the 1.0s scoring window.
    static func recordingDuration(forSoundID soundID: String) -> TimeInterval {
        shared?.scoringWindowSeconds ?? targetRecordingDuration
    }

    /// Backward-compatible lookup by phoneme label.
    static func reference(for phoneme: Phoneme) -> PhonemeReference? {
        shared?.phonemes[phoneme.modelLabel]
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
