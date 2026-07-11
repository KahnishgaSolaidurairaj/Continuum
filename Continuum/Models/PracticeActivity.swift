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
    let symbol: String
    let exampleWord: String
    let linkedPhoneme: Phoneme

    /// All 44 English phonemes available in the Practice tab.
    static let allPhonemes: [PracticeTarget] = Phoneme.allCases.map { phoneme in
        PracticeTarget(
            id: phoneme.modelLabel,
            symbol: phoneme.symbol,
            exampleWord: phoneme.exampleWord,
            linkedPhoneme: phoneme
        )
    }

    /// Backward-compatible alias used by older call sites.
    static var sounds: [PracticeTarget] { allPhonemes }

    /// Display label used in headers and buttons.
    var displayLabel: String {
        "/\(symbol)/"
    }
}
