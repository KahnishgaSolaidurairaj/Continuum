import Foundation

/// A target speech sound the user practices producing.
enum Phoneme: String, CaseIterable, Codable, Identifiable, Sendable {
    case p = "p"
    case b = "b"
    case m = "m"
    case f = "f"
    case v = "v"
    case theta = "θ"
    case eth = "ð"
    case u = "u"
    case i = "i"

    var id: String { rawValue }

    /// IPA symbol shown in the UI.
    var symbol: String { rawValue }

    /// Example word for coaching context.
    var exampleWord: String {
        switch self {
        case .p: return "pop"
        case .b: return "bob"
        case .m: return "mom"
        case .f: return "fan"
        case .v: return "van"
        case .theta: return "think"
        case .eth: return "this"
        case .u: return "boot"
        case .i: return "beat"
        }
    }

    /// Short articulatory hint shown before recording.
    var instruction: String {
        switch self {
        case .p:
            return "Close lips, build pressure, then release a sharp puff of air."
        case .b:
            return "Close lips like /p/, but voice the sound as you release."
        case .m:
            return "Close lips and hum steadily through your nose."
        case .f:
            return "Rest upper teeth on lower lip and blow air continuously."
        case .v:
            return "Same lip position as /f/, but add voice."
        case .theta:
            return "Place tongue tip near upper teeth and blow gently."
        case .eth:
            return "Same tongue position as /θ/, but add voice."
        case .u:
            return "Round lips and produce a steady back vowel."
        case .i:
            return "Spread lips slightly and produce a steady front vowel."
        }
    }

    /// Whether this phoneme is supported for audio-only demo coaching.
    var isAudioDemoSupported: Bool {
        true
    }

    /// Whether this phoneme is supported well enough for rule-based coaching in MVP.
    var isMVPSupported: Bool {
        switch self {
        case .theta, .eth:
            return false
        default:
            return true
        }
    }

    /// Audio-focused coaching hint for the demo mode.
    var audioInstruction: String {
        switch self {
        case .p:
            return "Say a sharp /p/ — listen for a quick burst of air with no voice."
        case .b:
            return "Say /b/ — same burst as /p/, but add voice in your throat."
        case .m:
            return "Hum /m/ steadily — keep voice on and hold the sound."
        case .f:
            return "Blow a continuous /f/ — steady airflow, no voice."
        case .v:
            return "Say /v/ — airflow like /f/ with voice added."
        case .theta:
            return "Say /θ/ — gentle fricative airflow between tongue and teeth."
        case .eth:
            return "Say /ð/ — same as /θ/ but voiced."
        case .u:
            return "Hold a steady /u/ vowel with continuous voice."
        case .i:
            return "Hold a steady /i/ vowel with continuous voice."
        }
    }

    /// Phonemes recommended for first release, in practice order.
    static var mvpOrder: [Phoneme] {
        [.m, .p, .b, .f, .v, .i, .u]
    }
}
