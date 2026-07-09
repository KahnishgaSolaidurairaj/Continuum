import Foundation

/// Difficulty tiers for the Flash activity.
enum FlashLevel: Int, CaseIterable, Identifiable, Sendable {
    case letter = 1
    case shortWords = 2
    case longWords = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .letter: return "Level 1"
        case .shortWords: return "Level 2"
        case .longWords: return "Level 3"
        }
    }

    var subtitle: String {
        switch self {
        case .letter: return "Letter + sound"
        case .shortWords: return "Short words"
        case .longWords: return "Longer words"
        }
    }
}

/// Kid-friendly words grouped by practice target and flash level.
enum FlashWordBank {
    /// Returns practice words for the chosen target and level.
    /// - Parameters:
    ///   - target: The letter or sound being practiced.
    ///   - level: The selected flash difficulty tier.
    /// - Returns: Words that highlight the target sound.
    static func words(for target: PracticeTarget, level: FlashLevel) -> [String] {
        switch level {
        case .letter:
            return [target.exampleWord]
        case .shortWords:
            return shortWords[target.id] ?? [target.exampleWord]
        case .longWords:
            return longWords[target.id] ?? [target.exampleWord]
        }
    }

    private static let shortWords: [String: [String]] = [
        "m": ["mom", "map", "ham", "gum"],
        "p": ["pop", "pup", "pan", "pea"],
        "b": ["bob", "bat", "bus", "bed"],
        "f": ["fan", "fun", "fog", "fin"],
        "v": ["van", "vet", "vow"],
        "i": ["sit", "big", "hit", "dig"],
        "u": ["cup", "sun", "bug", "mud"],
        "theta": ["thin", "math", "path"],
        "eth": ["this", "that", "them"]
    ]

    private static let longWords: [String: [String]] = [
        "m": ["animal", "summer", "family", "monkey", "tomato"],
        "p": ["apple", "happy", "purple", "people", "pencil"],
        "b": ["baby", "bubble", "rabbit", "balloon", "bedroom"],
        "f": ["flower", "family", "friend", "finish", "forest"],
        "v": ["seven", "river", "travel", "velvet", "adventure"],
        "i": ["kitten", "little", "pillow", "chicken", "bicycle"],
        "u": ["music", "unicorn", "computer", "umbrella", "sunshine"],
        "theta": ["nothing", "tooth", "birthday", "something", "bathroom"],
        "eth": ["mother", "brother", "weather", "together", "feather"]
    ]
}
