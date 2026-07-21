import Foundation

/// JSON representation of one highlighted word in the practice manifest.
struct ManifestWordEntry: Codable, Sendable {
    let word: String
    let highlights: [ManifestHighlightEntry]
}

/// One highlighted character range stored in the practice manifest.
struct ManifestHighlightEntry: Codable, Sendable {
    let start: Int
    let length: Int
}

/// JSON representation of one practice sound in the manifest.
struct PracticeSoundManifestEntry: Codable, Sendable {
    let id: String
    let displayName: String
    let traceCharacter: String
    let category: String
    let linkedPhoneme: String
    let playbackFile: String
    let level1Word: ManifestWordEntry
    let level2Words: [ManifestWordEntry]
    let level3Words: [ManifestWordEntry]
}

/// Top-level practice sounds manifest bundled with the app.
struct PracticeSoundsManifest: Codable, Sendable {
    let version: Int
    let targetDurationSeconds: Double
    let sounds: [PracticeSoundManifestEntry]
}

/// Loads practice sounds from `PracticeSoundsManifest.json`.
enum PracticeSoundsManifestLoader {
    private static let resourceName = "PracticeSoundsManifest"

    /// Shared manifest loaded from the app bundle.
    static let shared: PracticeSoundsManifest? = loadFromBundle()

    /// Every practice sound decoded from the manifest.
    /// - Returns: Catalog entries, or an empty array when loading fails.
    static func loadPracticeSounds() -> [PracticeSound] {
        guard let manifest = shared else { return [] }
        return manifest.sounds.map(makePracticeSound(from:))
    }

    /// Default recording duration stored in the manifest.
    static var targetRecordingDuration: TimeInterval {
        shared?.targetDurationSeconds ?? 2.0
    }

    private static func loadFromBundle() -> PracticeSoundsManifest? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(PracticeSoundsManifest.self, from: data)
        } catch {
            return nil
        }
    }

    private static func makePracticeSound(from entry: PracticeSoundManifestEntry) -> PracticeSound {
        PracticeSound(
            id: entry.id,
            displayName: entry.displayName,
            traceCharacter: entry.traceCharacter,
            category: mapCategory(entry.category),
            linkedPhoneme: resolvePhoneme(label: entry.linkedPhoneme),
            playbackFile: entry.playbackFile,
            level1Example: makeExample(from: entry.level1Word),
            level2Examples: entry.level2Words.map(makeExample(from:)),
            level3Examples: entry.level3Words.map(makeExample(from:))
        )
    }

    private static func makeExample(from entry: ManifestWordEntry) -> EnglishExample {
        EnglishExample(
            word: entry.word,
            highlights: entry.highlights.map {
                SoundHighlight(start: $0.start, length: $0.length)
            }
        )
    }

    private static func mapCategory(_ rawValue: String) -> PracticeSoundCategory {
        switch rawValue {
        case "vowel": return .vowel
        case "consonant": return .consonant
        case "vowelTeam": return .vowelTeam
        default: return .consonant
        }
    }

    private static func resolvePhoneme(label: String) -> Phoneme {
        if let match = Phoneme.allCases.first(where: { $0.modelLabel == label }) {
            return match
        }
        if let match = Phoneme(rawValue: label) {
            return match
        }
        switch label {
        case "th": return .theta
        case "th_voiced": return .eth
        case "er": return .er
        case "ou": return .ow
        default: return .m
        }
    }
}
