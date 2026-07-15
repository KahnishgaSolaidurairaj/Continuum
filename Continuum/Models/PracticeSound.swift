import Foundation

/// Category used to organize practice sounds on the picker screen.
enum PracticeSoundCategory: String, Codable, Sendable {
    case vowel
    case consonant
    case vowelTeam
}

/// One practice sound derived from the 44-sound English curriculum.
struct PracticeSound: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let traceCharacter: String
    let category: PracticeSoundCategory
    let linkedPhoneme: Phoneme
    let playbackFile: String
    let level1Example: EnglishExample
    let level2Examples: [EnglishExample]
    let level3Examples: [EnglishExample]

    var symbol: String { displayName }

    var primaryExample: String {
        level1Example.word
    }

    /// Highlights for a known flash word when available.
    func highlights(for word: String) -> [SoundHighlight] {
        let examples = [level1Example] + level2Examples + level3Examples
        return examples.first(where: { $0.word.caseInsensitiveCompare(word) == .orderedSame })?.highlights ?? []
    }
}

/// Maps curriculum sound IDs to bundled reference-audio and embedding asset keys.
enum PracticeSoundAssetBridge {
    /// Reference-audio / embedding key used in bundled phoneme assets.
    static func assetKey(forSoundID soundID: String) -> String {
        curriculumToAssetKey[soundID] ?? soundID
    }

    /// Resolves legacy manifest IDs to current curriculum IDs.
    static func canonicalSoundID(_ soundID: String) -> String {
        legacySoundIDAliases[soundID] ?? soundID
    }

    /// Primary reference clip filename for a curriculum sound.
    static func playbackFile(forSoundID soundID: String) -> String {
        let assetKey = assetKey(forSoundID: soundID)
        return "\(assetKey)_ref_01.wav"
    }

    private static let curriculumToAssetKey: [String: String] = [
        "short_a": "ae",
        "short_e": "e",
        "short_i": "i",
        "short_o": "o",
        "short_u": "uh",
        "long_a": "ae",
        "long_e": "ee",
        "long_i": "ie",
        "long_o": "oa",
        "long_u": "u",
        "long_oo": "oo",
        "th_voiceless": "th",
        "th_voiced": "th_voiced",
        "hw": "w",
        "nk": "n",
        "ur": "er",
        "ow": "ou"
    ]

    private static let legacySoundIDAliases: [String: String] = [
        "a": "short_a",
        "ae": "short_a",
        "e": "short_e",
        "i": "short_i",
        "o": "short_o",
        "uh": "short_u",
        "ee": "long_e",
        "ie": "long_i",
        "oa": "long_o",
        "u": "long_u",
        "oo": "long_oo",
        "th": "th_voiceless",
        "er": "ur",
        "ou": "ow"
    ]
}

/// Loads the 44 English sounds for practice flows.
enum PracticeSoundCatalog {
    private static let loadedSounds: [PracticeSound] = buildSounds()

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
        PhonemeReferenceCatalog.targetRecordingDuration
    }

    /// Returns one practice sound by ID, including legacy manifest aliases.
    /// - Parameter id: Practice sound identifier.
    /// - Returns: Matching sound, if present.
    static func sound(withID id: String) -> PracticeSound? {
        let canonicalID = PracticeSoundAssetBridge.canonicalSoundID(id)
        return loadedSounds.first(where: { $0.id == canonicalID })
    }

    private static func buildSounds() -> [PracticeSound] {
        EnglishSound.allSounds.map { englishSound in
            PracticeSound(
                id: englishSound.id,
                displayName: englishSound.displayName,
                traceCharacter: englishSound.traceCharacter,
                category: mapCategory(englishSound.category),
                linkedPhoneme: englishSound.linkedPhoneme,
                playbackFile: PracticeSoundAssetBridge.playbackFile(forSoundID: englishSound.id),
                level1Example: englishSound.level1Example,
                level2Examples: englishSound.level2Examples,
                level3Examples: englishSound.level3Examples
            )
        }
    }

    private static func mapCategory(_ category: EnglishSoundCategory) -> PracticeSoundCategory {
        switch category {
        case .vowel: return .vowel
        case .consonant: return .consonant
        case .vowelTeam: return .vowelTeam
        }
    }
}
