import Foundation

/// Category used to organize practice sounds on the picker screen.
enum PracticeSoundCategory: String, Codable, Sendable {
    case vowel
    case consonant
    case vowelTeam
}

/// One practice sound loaded from the bundled PhonemeAudio manifest.
struct PracticeSound: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let traceCharacter: String
    let category: PracticeSoundCategory
    let linkedPhoneme: Phoneme
    let playbackFile: String
    let level2Examples: [EnglishExample]
    let level3Examples: [EnglishExample]

    var symbol: String { displayName }

    var primaryExample: String {
        level2Examples.first?.word ?? displayName
    }

    /// Highlights for a known flash word when available.
    func highlights(for word: String) -> [SoundHighlight] {
        let examples = level2Examples + level3Examples
        return examples.first(where: { $0.word.caseInsensitiveCompare(word) == .orderedSame })?.highlights ?? []
    }
}

/// Decodable manifest payload bundled with the app.
private struct PracticeSoundsManifest: Codable {
    let version: Int
    let targetDurationSeconds: Double
    let sounds: [PracticeSoundRecord]
}

private struct PracticeSoundRecord: Codable {
    let id: String
    let displayName: String
    let traceCharacter: String
    let category: PracticeSoundCategory
    let linkedPhoneme: String
    let playbackFile: String
    let level2Words: [ManifestWordExample]
    let level3Words: [ManifestWordExample]
}

private struct ManifestWordExample: Codable {
    let word: String
    let highlights: [ManifestHighlight]
}

private struct ManifestHighlight: Codable {
    let start: Int
    let length: Int
}

/// Loads bundled practice sounds generated from PhonemeAudio ingest.
enum PracticeSoundCatalog {
    private static let resourceName = "PracticeSoundsManifest"
    private static let loadedSounds: [PracticeSound] = loadSounds()

    /// Every practice sound available in the Practice tab.
    static var allSounds: [PracticeSound] { loadedSounds }

    static var vowels: [PracticeSound] {
        loadedSounds.filter { $0.category == .vowel }
    }

    static var consonants: [PracticeSound] {
        loadedSounds.filter { $0.category == .consonant }
    }

    static var vowelTeams: [PracticeSound] {
        loadedSounds.filter { $0.category == .vowelTeam }
    }

    /// Bundled recording duration used by the Test activity.
    static var targetRecordingDuration: TimeInterval {
        manifest()?.targetDurationSeconds ?? 1.0
    }

    /// Returns one practice sound by ID.
    /// - Parameter id: Practice sound identifier.
    /// - Returns: Matching sound, if present.
    static func sound(withID id: String) -> PracticeSound? {
        loadedSounds.first(where: { $0.id == id })
    }

    private static func manifest() -> PracticeSoundsManifest? {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(PracticeSoundsManifest.self, from: data) else {
            return nil
        }
        return manifest
    }

    private static func loadSounds() -> [PracticeSound] {
        guard let manifest = manifest() else { return [] }
        return manifest.sounds.compactMap { record in
            guard let phoneme = Phoneme(rawValue: record.linkedPhoneme) else { return nil }
            return PracticeSound(
                id: record.id,
                displayName: record.displayName,
                traceCharacter: record.traceCharacter,
                category: record.category,
                linkedPhoneme: phoneme,
                playbackFile: record.playbackFile,
                level2Examples: record.level2Words.map(convertExample),
                level3Examples: record.level3Words.map(convertExample)
            )
        }
    }

    private static func convertExample(_ example: ManifestWordExample) -> EnglishExample {
        EnglishExample(
            word: example.word,
            highlights: example.highlights.map {
                SoundHighlight(start: $0.start, length: $0.length)
            }
        )
    }
}
