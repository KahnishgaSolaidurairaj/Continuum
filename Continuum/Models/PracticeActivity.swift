import Foundation

/// A practice activity inside the carousel flow.
enum PracticeActivity: String, CaseIterable, Identifiable, Sendable {
    case sandbox
    case flash
    case tryDemo
    case test

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sandbox: return "Trace with your finger"
        case .flash: return "Flashcard"
        case .tryDemo: return "See an example"
        case .test: return "Try it yourself"
        }
    }

    var subtitle: String {
        switch self {
        case .sandbox: return "Sandbox"
        case .flash: return "Flash"
        case .tryDemo: return "Try"
        case .test: return "Test"
        }
    }

    var systemImage: String {
        switch self {
        case .sandbox: return "hand.draw"
        case .flash: return "speaker.wave.2.fill"
        case .tryDemo: return "play.rectangle.fill"
        case .test: return "mic.fill"
        }
    }
}

/// One of the 44 English phonemes the child can practice.
struct PracticeTarget: Identifiable, Hashable, Sendable {
    let id: String
    let englishSound: EnglishSound

    var symbol: String { englishSound.displayName }
    var exampleWord: String { englishSound.primaryExample }
    var linkedPhoneme: Phoneme { englishSound.linkedPhoneme }

    /// All 44 English sounds available in the Practice tab.
    static let allPhonemes: [PracticeTarget] = EnglishSound.allSounds.map { sound in
        PracticeTarget(id: sound.id, englishSound: sound)
    }

    /// Backward-compatible alias used by older call sites.
    static var sounds: [PracticeTarget] { allPhonemes }

    /// Display label used in headers and buttons.
    var displayLabel: String {
        englishSound.displayName
    }

    var traceCharacter: String {
        englishSound.traceCharacter
    }
}
