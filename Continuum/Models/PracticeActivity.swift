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

/// A letter or sound the child selects to practice.
struct PracticeTarget: Identifiable, Hashable, Sendable {
    let id: String
    let symbol: String
    let spelling: String
    let exampleWord: String
    let linkedPhoneme: Phoneme?

    /// Sounds with working audio scoring rules in the Test activity.
    static let sounds: [PracticeTarget] = [
        target("m", phoneme: .m, example: "mom"),
        target("p", phoneme: .p, example: "pop"),
        target("b", phoneme: .b, example: "bob"),
        target("f", phoneme: .f, example: "fan"),
        target("v", phoneme: .v, example: "van"),
        target("i", phoneme: .i, example: "beat"),
        target("u", phoneme: .u, example: "boot"),
        target("θ", id: "theta", phoneme: .theta, example: "think"),
        target("ð", id: "eth", phoneme: .eth, example: "this")
    ]

    /// Alphabet letters that map to a scored phoneme (subset of a–z).
    static let alphabet: [PracticeTarget] = sounds.filter { $0.spelling.count == 1 && $0.spelling != "θ" && $0.spelling != "ð" }

    private static func target(
        _ symbol: String,
        id: String? = nil,
        phoneme: Phoneme,
        example: String
    ) -> PracticeTarget {
        PracticeTarget(
            id: id ?? symbol,
            symbol: symbol,
            spelling: symbol,
            exampleWord: example,
            linkedPhoneme: phoneme
        )
    }
}
