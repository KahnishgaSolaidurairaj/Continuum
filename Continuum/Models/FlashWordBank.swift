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
        case .sound: return "Sound + word"
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
            return [target.exampleWord]
        case .shortWords:
            return shortWords[target.id] ?? [target.exampleWord]
        case .longWords:
            return longWords[target.id] ?? [target.exampleWord]
        }
    }

    private static let shortWords: [String: [String]] = [
        "p": ["pop", "pup", "pan", "pea"],
        "b": ["bob", "bat", "bus", "bed"],
        "t": ["top", "tap", "ten", "toy"],
        "d": ["dog", "dig", "dad", "dot"],
        "k": ["cat", "cup", "kit", "key"],
        "g": ["go", "gap", "gum", "got"],
        "m": ["mom", "map", "ham", "gum"],
        "n": ["nap", "net", "nut", "nine"],
        "ng": ["sing", "ring", "long", "bang"],
        "f": ["fan", "fun", "fog", "fin"],
        "v": ["van", "vet", "vow", "vine"],
        "theta": ["thin", "math", "path", "bath"],
        "eth": ["this", "that", "them", "then"],
        "s": ["sun", "sit", "soap", "seed"],
        "z": ["zip", "zoo", "zone", "zero"],
        "sh": ["ship", "shop", "shoe", "fish"],
        "zh": ["measure", "vision", "beige"],
        "ch": ["chip", "chat", "chop", "lunch"],
        "j": ["jump", "jet", "job", "judge"],
        "h": ["hat", "hop", "hot", "home"],
        "l": ["lip", "lap", "log", "lake"],
        "r": ["red", "run", "rip", "rain"],
        "w": ["wet", "win", "web", "wish"],
        "y": ["yes", "yak", "yell", "yard"],
        "i": ["beat", "see", "tree", "me"],
        "ih": ["bit", "sit", "hit", "dig"],
        "ay": ["bay", "day", "say", "rain"],
        "eh": ["bed", "red", "pen", "ten"],
        "ae": ["bat", "cat", "hat", "map"],
        "ah": ["father", "hot", "cot", "pond"],
        "aw": ["caught", "tall", "call", "walk"],
        "oh": ["go", "no", "so", "boat"],
        "u_short": ["book", "look", "good", "foot"],
        "u": ["boot", "moon", "food", "cool"],
        "uh": ["but", "cup", "sun", "bug"],
        "schwa": ["about", "sofa", "banana"],
        "ie": ["bite", "light", "time", "fly"],
        "ow": ["bout", "house", "cow", "now"],
        "oy": ["boy", "toy", "joy", "coin"],
        "er": ["bird", "turn", "her", "fur"],
        "ar": ["car", "star", "far", "park"],
        "or": ["horse", "for", "corn", "storm"],
        "air": ["hair", "fair", "chair", "care"],
        "ire": ["ear", "near", "here", "deer"]
    ]

    private static let longWords: [String: [String]] = [
        "p": ["apple", "happy", "purple", "people", "pencil"],
        "b": ["baby", "bubble", "rabbit", "balloon", "bedroom"],
        "t": ["tiger", "turtle", "butter", "kitchen", "picture"],
        "d": ["dragon", "dinner", "garden", "sunday", "shadow"],
        "k": ["kitten", "kitchen", "blanket", "bucket", "rocket"],
        "g": ["garden", "guitar", "giggle", "golden", "grocery"],
        "m": ["animal", "summer", "family", "monkey", "tomato"],
        "n": ["animal", "banana", "dinner", "winter", "planet"],
        "ng": ["singing", "morning", "springtime", "humming", "ringing"],
        "f": ["flower", "family", "friend", "finish", "forest"],
        "v": ["seven", "river", "travel", "velvet", "adventure"],
        "theta": ["nothing", "tooth", "birthday", "something", "bathroom"],
        "eth": ["mother", "brother", "weather", "together", "feather"],
        "s": ["sunshine", "sister", "castle", "dessert", "musical"],
        "z": ["puzzle", "frozen", "lizard", "buzzer", "amazing"],
        "sh": ["shadow", "fishing", "washing", "shower", "treasure"],
        "zh": ["measure", "treasure", "vision", "pleasure"],
        "ch": ["chicken", "kitchen", "teacher", "lunchbox", "chimney"],
        "j": ["jungle", "jacket", "project", "enjoying", "journey"],
        "h": ["happy", "house", "hospital", "holiday", "hundred"],
        "l": ["little", "yellow", "pillow", "family", "balloon"],
        "r": ["rabbit", "rainbow", "brother", "forest", "morning"],
        "w": ["water", "winter", "window", "wonder", "weather"],
        "y": ["yellow", "yogurt", "beyond", "canyon", "royal"],
        "i": ["kitten", "little", "pillow", "chicken", "bicycle"],
        "ih": ["kitten", "little", "pillow", "chicken", "bicycle"],
        "ay": ["rainbow", "holiday", "today", "maybe", "playing"],
        "eh": ["breakfast", "remember", "together", "yellow", "letter"],
        "ae": ["animal", "family", "candle", "planet", "travel"],
        "ah": ["honest", "promise", "dollar", "waffle", "pocket"],
        "aw": ["awesome", "drawing", "strawberry", "caution", "laundry"],
        "oh": ["ocean", "open", "over", "broken", "golden"],
        "u_short": ["cooking", "football", "wooden", "goodbye", "cushion"],
        "u": ["music", "unicorn", "computer", "umbrella", "sunshine"],
        "uh": ["butter", "summer", "number", "hundred", "tunnel"],
        "schwa": ["banana", "sofa", "about", "lemon", "camel"],
        "ie": ["bicycle", "diamond", "library", "science", "firefly"],
        "ow": ["flower", "outside", "shower", "mountain", "cowboy"],
        "oy": ["enjoy", "royal", "oyster", "cowboy", "destroy"],
        "er": ["teacher", "sister", "winter", "burger", "circle"],
        "ar": ["garden", "market", "sparkle", "harmony", "carpet"],
        "or": ["forest", "morning", "important", "explorer", "cornfield"],
        "air": ["fairytale", "airplane", "hairbrush", "staircase", "dairy"],
        "ire": ["earring", "pioneer", "cheerful", "nearby", "deer"]
    ]
}
