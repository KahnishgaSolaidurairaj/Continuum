import Foundation

/// A time-bounded clip from the shared pronunciation YouTube guide.
struct PronunciationVideoClip: Sendable, Hashable {
    let videoID: String
    let startSeconds: Double
    let endSeconds: Double

    /// Opens the full YouTube video in the browser or YouTube app.
    var fullVideoURL: URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    }

    /// Opens the full video starting near this sound's clip.
    var fullVideoURLAtClip: URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)&t=\(Int(startSeconds))s")!
    }
}

/// Maps each practice sound to a clip in the shared pronunciation video.
enum PronunciationVideoCatalog {
    /// Shared guide: https://www.youtube.com/watch?v=tpN9CPwZ-oE
    static let sharedVideoID = "tpN9CPwZ-oE"

    /// Returns the clip for a practice sound when a timestamp range is configured.
    /// - Parameter soundID: The `PracticeSound.id` from `PracticeSoundsManifest.json`.
    /// - Returns: The clip to play, or `nil` when no timestamp is mapped for that sound.
    static func clip(for soundID: String) -> PronunciationVideoClip? {
        guard let range = clipRanges[soundID] else { return nil }
        return PronunciationVideoClip(
            videoID: sharedVideoID,
            startSeconds: range.start,
            endSeconds: range.end
        )
    }

    /// Start/end seconds keyed by manifest sound ID (and legacy aliases).
    private static let clipRanges: [String: (start: Double, end: Double)] = [
        // Vowels — IDs match PracticeSoundsManifest.json
        "a": (57, 65),              // /a/
        "ae": (57, 65),             // Short /ae/ (same clip as Short /a/)
        "e": (65, 72),              // Short /e/
        "i": (72, 90),              // Short /i/
        "o": (90, 97),              // Short /o/
        "uh": (97, 104),            // Short /u/
        "ee": (116, 123),           // Long /e/
        "ie": (123, 131),           // Long /i/
        "oa": (131, 142),           // Long /o/
        "u": (142, 152),            // Long /u/
        "oo": (152, 160),           // Long /oo/

        // Consonants
        "b": (178, 186),
        "k": (186, 194),
        "d": (194, 216),
        "f": (216, 228),
        "g": (227, 235),
        "h": (235, 243),
        "j": (243, 252),
        "l": (252, 266),
        "m": (266, 276),
        "n": (276, 302),
        "p": (302, 310),
        "r": (310, 317),
        "s": (317, 328),
        "t": (328, 345),
        "v": (345, 355),
        "w": (355, 364),
        "y": (364, 372),
        "z": (372, 382),
        "ch": (384, 391),
        "sh": (391, 403),
        "th": (403, 412),           // Unvoiced /th/
        "th_voiced": (412, 421),
        "ng": (447, 458),

        // Vowel teams
        "er": (471, 482),           // /er/ — same video section as /ur/
        "ar": (482, 491),
        "or": (491, 498),
        "oi": (503, 526),
        "ou": (526, 534),           // /ou/ — same video section as /ow/
        "oo_short": (534, 541),
        "aw": (541, 549),
        "zh": (549, 556),

        // Legacy EnglishSound IDs (backward compatibility)
        "short_a": (57, 65),
        "short_e": (65, 72),
        "short_i": (72, 90),
        "short_o": (90, 97),
        "short_u": (97, 104),
        "long_a": (105, 116),
        "long_e": (116, 123),
        "long_i": (123, 131),
        "long_o": (131, 142),
        "long_u": (142, 152),
        "long_oo": (152, 160),
        "th_voiceless": (403, 412),
        "hw": (421, 447),
        "nk": (458, 466),
        "ur": (471, 482),
        "ow": (526, 534)
    ]
}
