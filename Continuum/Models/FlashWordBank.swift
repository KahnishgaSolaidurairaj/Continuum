import Foundation

/// Difficulty tiers for the Flash activity.
enum FlashLevel: Int, CaseIterable, Identifiable, Sendable {
    case sound = 1
    case shortWords = 2
    case longWords = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .sound: return "Level 1"
        case .shortWords: return "Level 2"
        case .longWords: return "Level 3"
        }
    }

    var subtitle: String {
        switch self {
        case .sound: return "Sound"
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
        case .sound:
            return [target.practiceSound.level1Example.word]
        case .shortWords:
            return target.practiceSound.level2Examples.map(\.word)
        case .longWords:
            return target.practiceSound.level3Examples.map(\.word)
        }
    }

    /// Returns highlight ranges for a flash word when known.
    static func highlights(for target: PracticeTarget, word: String) -> [SoundHighlight] {
        target.practiceSound.highlights(for: word)
    }
}
