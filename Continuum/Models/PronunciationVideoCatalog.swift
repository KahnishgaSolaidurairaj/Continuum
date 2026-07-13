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

/// Maps each English sound to a clip in the shared pronunciation video.
enum PronunciationVideoCatalog {
    /// Shared guide: https://www.youtube.com/watch?v=tpN9CPwZ-oE
    static let sharedVideoID = "tpN9CPwZ-oE"

    /// Returns the clip for a practice sound when a timestamp range is configured.
    /// - Parameter soundID: The `EnglishSound.id` being practiced.
    /// - Returns: The clip to play, or `nil` when timestamps still need to be added.
    static func clip(for soundID: String) -> PronunciationVideoClip? {
        guard let range = clipRanges[soundID] else { return nil }
        return PronunciationVideoClip(
            videoID: sharedVideoID,
            startSeconds: range.start,
            endSeconds: range.end
        )
    }

    /// Start/end seconds for each sound in the shared YouTube guide.
    private static let clipRanges: [String: (start: Double, end: Double)] = [
        // Vowels
        "short_a": (57, 65),       // 0:57–1:05  Apple, After
        "short_e": (65, 72),       // 1:05–1:12  Every, Pen
        "short_i": (72, 90),       // 1:12–1:30  Interest, Busy, English
        "short_o": (90, 97),       // 1:30–1:37  October, Water
        "short_u": (97, 104),      // 1:37–1:44  Under, Fun
        "long_a": (105, 116),      // 1:45–1:56  Make, Flavor
        "long_e": (116, 123),      // 1:56–2:03  Feet, Evening
        "long_i": (123, 131),      // 2:03–2:11  Lie, Night
        "long_o": (131, 142),      // 2:11–2:22  Over, Open
        "long_u": (142, 152),      // 2:22–2:32  Unique, Rescue
        "long_oo": (152, 160),     // 2:32–2:40  Flew, Blue, Group

        // Consonants
        "b": (178, 186),           // 2:58–3:06  Bat, Bear, Bubbles
        "k": (186, 194),           // 3:06–3:14  Care, Kindness
        "d": (194, 216),           // 3:14–3:36  Add, Different, Better
        "f": (216, 228),           // 3:36–3:48  Fan, Phone, Often, Enough
        "g": (227, 235),           // 3:47–3:55  Get, Guest, Egg
        "h": (235, 243),           // 3:55–4:03  Hat, Happy, Who
        "j": (243, 252),           // 4:03–4:12  Jewelry, Giraffe, Edge
        "l": (252, 266),           // 4:12–4:26  Life, Love, Laughter
        "m": (266, 276),           // 4:26–4:36  Map, Summer, Some
        "n": (276, 302),           // 4:36–5:02  Funny, Nose, Know
        "p": (302, 310),           // 5:02–5:10  Pig, Please, Flip
        "r": (310, 317),           // 5:10–5:17  Run, Carrot
        "s": (317, 328),           // 5:17–5:28  Sun, Circle, Pace, Course
        "t": (328, 345),           // 5:28–5:45  Top, Watched, Sweater
        "v": (345, 355),           // 5:45–5:55  Five, Of
        "w": (355, 364),           // 5:55–6:04  Went, Quick, Why
        "y": (364, 372),           // 6:04–6:12  Yellow, Yes, Yay
        "z": (372, 382),           // 6:12–6:22  Zip, Scissors, His
        "ch": (384, 391),          // 6:24–6:31  Touch, Chin
        "sh": (391, 403),          // 6:31–6:43  Ship, Shape
        "th_voiceless": (403, 412), // 6:43–6:52  Thin, Thursday
        "th_voiced": (412, 421),   // 6:52–7:01  This, That, These, Those
        "hw": (421, 447),          // 7:01–7:27  Whip, When
        "ng": (447, 458),          // 7:27–7:38  Sing, Bring, Going
        "nk": (458, 466),          // 7:38–7:46  Sink, Blink, Crank
        "zh": (549, 556),          // 9:09–9:16  Television

        // Vowel teams
        "ur": (471, 482),          // 7:51–8:02  Bird, Turn, Her
        "ar": (482, 491),          // 8:02–8:11  Park, Dark
        "or": (491, 498),          // 8:11–8:18  Fork, Pork
        "oi": (503, 526),          // 8:23–8:46  Boy, Toy
        "ow": (526, 534),          // 8:46–8:54  Owl, Ouch
        "oo_short": (534, 541),    // 8:54–9:01  Cool, Pull
        "aw": (541, 549)           // 9:01–9:09  Jaw, Haul
    ]
}
