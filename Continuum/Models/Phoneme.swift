import Foundation

/// Articulation style used by rule-based fallback scoring.
enum ArticulationKind: Sendable {
    case stopUnvoiced
    case stopVoiced
    case nasal
    case fricativeUnvoiced
    case fricativeVoiced
    case affricateUnvoiced
    case affricateVoiced
    case glide
    case liquid
    case vowel
}

/// A target speech sound the user practices producing.
enum Phoneme: String, CaseIterable, Codable, Identifiable, Sendable {
    // MARK: - Consonants (24)

    case p, b, t, d, k, g, ks, kw
    case m, n, ng
    case f, v, theta, eth, s, z, sh, zh, ch, j, h
    case l, r, w, y

    // MARK: - Vowels (20)

    case i, ih, ay, eh, ae, ah, aw, oh, u_short, u, uh, schwa
    case ie, ow, oy, er, ar, or_vowel, air, ire

    var id: String { modelLabel }

    /// IPA symbol shown in the UI.
    var symbol: String {
        switch self {
        case .p: return "p"
        case .b: return "b"
        case .t: return "t"
        case .d: return "d"
        case .k: return "k"
        case .g: return "g"
        case .ks: return "ks"
        case .kw: return "kw"
        case .m: return "m"
        case .n: return "n"
        case .ng: return "ŋ"
        case .f: return "f"
        case .v: return "v"
        case .theta: return "θ"
        case .eth: return "ð"
        case .s: return "s"
        case .z: return "z"
        case .sh: return "ʃ"
        case .zh: return "ʒ"
        case .ch: return "tʃ"
        case .j: return "dʒ"
        case .h: return "h"
        case .l: return "l"
        case .r: return "r"
        case .w: return "w"
        case .y: return "j"
        case .i: return "i"
        case .ih: return "ɪ"
        case .ay: return "eɪ"
        case .eh: return "ɛ"
        case .ae: return "æ"
        case .ah: return "ɑ"
        case .aw: return "ɔ"
        case .oh: return "oʊ"
        case .u_short: return "ʊ"
        case .u: return "u"
        case .uh: return "ʌ"
        case .schwa: return "ə"
        case .ie: return "aɪ"
        case .ow: return "aʊ"
        case .oy: return "ɔɪ"
        case .er: return "ɜr"
        case .ar: return "ɑr"
        case .or_vowel: return "ɔr"
        case .air: return "ɛr"
        case .ire: return "ɪr"
        }
    }

    /// Human-readable phoneme name for accessibility labels.
    var displayName: String {
        switch self {
        case .p: return "P"
        case .b: return "B"
        case .t: return "T"
        case .d: return "D"
        case .k: return "K"
        case .g: return "G"
        case .ks: return "KS"
        case .kw: return "KW"
        case .m: return "M"
        case .n: return "N"
        case .ng: return "NG"
        case .f: return "F"
        case .v: return "V"
        case .theta: return "TH voiceless"
        case .eth: return "TH voiced"
        case .s: return "S"
        case .z: return "Z"
        case .sh: return "SH"
        case .zh: return "ZH"
        case .ch: return "CH"
        case .j: return "J"
        case .h: return "H"
        case .l: return "L"
        case .r: return "R"
        case .w: return "W"
        case .y: return "Y"
        case .i: return "long E"
        case .ih: return "short I"
        case .ay: return "long A"
        case .eh: return "short E"
        case .ae: return "short A"
        case .ah: return "AH"
        case .aw: return "AW"
        case .oh: return "long O"
        case .u_short: return "short OO"
        case .u: return "long OO"
        case .uh: return "short U"
        case .schwa: return "schwa"
        case .ie: return "long I"
        case .ow: return "OW"
        case .oy: return "OY"
        case .er: return "ER"
        case .ar: return "AR"
        case .or_vowel: return "OR"
        case .air: return "AIR"
        case .ire: return "IRE"
        }
    }

    /// Example word for coaching context.
    var exampleWord: String {
        switch self {
        case .p: return "pop"
        case .b: return "bob"
        case .t: return "top"
        case .d: return "dog"
        case .k: return "cat"
        case .g: return "go"
        case .ks: return "box"
        case .kw: return "queen"
        case .m: return "mom"
        case .n: return "nap"
        case .ng: return "sing"
        case .f: return "fan"
        case .v: return "van"
        case .theta: return "think"
        case .eth: return "this"
        case .s: return "sun"
        case .z: return "zip"
        case .sh: return "ship"
        case .zh: return "measure"
        case .ch: return "chip"
        case .j: return "jump"
        case .h: return "hat"
        case .l: return "lip"
        case .r: return "red"
        case .w: return "wet"
        case .y: return "yes"
        case .i: return "beat"
        case .ih: return "bit"
        case .ay: return "bay"
        case .eh: return "bed"
        case .ae: return "bat"
        case .ah: return "father"
        case .aw: return "caught"
        case .oh: return "go"
        case .u_short: return "book"
        case .u: return "boot"
        case .uh: return "but"
        case .schwa: return "about"
        case .ie: return "bite"
        case .ow: return "bout"
        case .oy: return "boy"
        case .er: return "bird"
        case .ar: return "car"
        case .or_vowel: return "horse"
        case .air: return "hair"
        case .ire: return "ear"
        }
    }

    /// Short articulatory hint shown before recording.
    var instruction: String {
        switch articulationKind {
        case .stopUnvoiced:
            return "Build pressure, then release a quick puff of air with no voice."
        case .stopVoiced:
            return "Build pressure like an unvoiced stop, then release with voice."
        case .nasal:
            return "Keep your mouth closed or open for /n/ and /ŋ/, and let sound resonate through your nose."
        case .fricativeUnvoiced:
            return "Create steady turbulent airflow without turning on your voice."
        case .fricativeVoiced:
            return "Create steady airflow and add voice in your throat."
        case .affricateUnvoiced:
            return "Start with a quick stop release, then continue into a short fricative."
        case .affricateVoiced:
            return "Start with a voiced stop release, then continue into a short voiced fricative."
        case .glide:
            return "Keep the sound smooth and continuous without stopping the airflow."
        case .liquid:
            return "Hold a smooth voiced sound with relaxed tongue movement."
        case .vowel:
            return "Hold one steady vowel sound with continuous voice."
        }
    }

    /// Whether this phoneme is supported for audio-only demo coaching.
    var isAudioDemoSupported: Bool { true }

    /// Whether this phoneme is supported well enough for rule-based coaching in MVP.
    var isMVPSupported: Bool { true }

    /// Audio-focused coaching hint for the demo mode.
    var audioInstruction: String {
        "Say /\(symbol)/ in “\(exampleWord)” — \(instruction)"
    }

    /// All consonant phonemes in practice order.
    static var consonants: [Phoneme] {
        [.p, .b, .t, .d, .k, .g, .ks, .kw, .m, .n, .ng, .f, .v, .theta, .eth, .s, .z, .sh, .zh, .ch, .j, .h, .l, .r, .w, .y]
    }

    /// All vowel phonemes in practice order.
    static var vowels: [Phoneme] {
        [.i, .ih, .ay, .eh, .ae, .ah, .aw, .oh, .u_short, .u, .uh, .schwa, .ie, .ow, .oy, .er, .ar, .or_vowel, .air, .ire]
    }

    /// Phonemes recommended for first release, in practice order.
    static var mvpOrder: [Phoneme] {
        [.m, .p, .b, .f, .v, .i, .u]
    }

    /// Folder / model label used by Create ML and bundled reference assets.
    var modelLabel: String {
        switch self {
        case .theta: return "theta"
        case .eth: return "eth"
        case .ng: return "ng"
        case .sh: return "sh"
        case .zh: return "zh"
        case .ch: return "ch"
        case .j: return "j"
        case .ih: return "ih"
        case .ay: return "ay"
        case .eh: return "eh"
        case .ae: return "ae"
        case .ah: return "ah"
        case .aw: return "aw"
        case .oh: return "oh"
        case .u_short: return "u_short"
        case .uh: return "uh"
        case .schwa: return "schwa"
        case .ie: return "ie"
        case .ow: return "ow"
        case .oy: return "oy"
        case .er: return "er"
        case .ar: return "ar"
        case .or_vowel: return "or"
        case .air: return "air"
        case .ire: return "ire"
        default: return rawValue
        }
    }

    /// Class label representing silence, coughs, and background noise.
    static let noiseModelLabel = "noise"

    /// Labels expected in `PhonemeClassifier.mlmodel`, including the noise class.
    static var modelLabels: [String] {
        allCases.map(\.modelLabel) + [noiseModelLabel]
    }

    /// How ML window confidences should be aggregated into one score for this sound.
    var mlAggregation: MLAggregation {
        switch articulationKind {
        case .stopUnvoiced, .stopVoiced, .affricateUnvoiced, .affricateVoiced:
            return .transient
        default:
            return .sustained
        }
    }

    /// Rule-based scoring category for this phoneme.
    var articulationKind: ArticulationKind {
        switch self {
        case .p, .t, .k, .ks: return .stopUnvoiced
        case .b, .d, .g: return .stopVoiced
        case .m, .n, .ng: return .nasal
        case .f, .theta, .s, .sh, .h: return .fricativeUnvoiced
        case .v, .eth, .z, .zh: return .fricativeVoiced
        case .ch: return .affricateUnvoiced
        case .j: return .affricateVoiced
        case .w, .y, .kw: return .glide
        case .l, .r: return .liquid
        case .i, .ih, .ay, .eh, .ae, .ah, .aw, .oh, .u_short, .u, .uh, .schwa, .ie, .ow, .oy, .er, .ar, .or_vowel, .air, .ire:
            return .vowel
        }
    }
}

/// Strategy for turning many per-window confidences into a single accuracy score.
enum MLAggregation {
    case sustained
    case transient
}
