import Foundation

/// A character range within a word that produces the target sound.
struct SoundHighlight: Hashable, Sendable {
    let start: Int
    let length: Int
}

/// An example word with the sound-producing letters marked for visual emphasis.
struct EnglishExample: Hashable, Sendable {
    let word: String
    let highlights: [SoundHighlight]
}

/// Category used to organize the 44 English sounds on the practice picker screen.
enum EnglishSoundCategory: String, Sendable {
    case vowel
    case consonant
    case vowelTeam
}

/// One of the 44 kid-friendly English sounds used across Continuum practice flows.
struct EnglishSound: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let level1Example: EnglishExample
    let level2Examples: [EnglishExample]
    let level3Examples: [EnglishExample]
    let linkedPhoneme: Phoneme
    let category: EnglishSoundCategory
    let traceCharacter: String

    var symbol: String { displayName }

    /// Every catalogued example word for this sound.
    var examples: [EnglishExample] {
        [level1Example] + level2Examples + level3Examples
    }

    var primaryExample: String {
        level1Example.word
    }

    /// Highlights for a known example or flash word, when available.
    func highlights(for word: String) -> [SoundHighlight] {
        examples.first(where: { $0.word.caseInsensitiveCompare(word) == .orderedSame })?.highlights ?? []
    }

    /// All 44 English sounds in teaching order.
    static let allSounds: [EnglishSound] = EnglishSoundCatalog.sounds

    static var vowels: [EnglishSound] {
        allSounds.filter { $0.category == .vowel }
    }

    static var consonants: [EnglishSound] {
        allSounds.filter { $0.category == .consonant }
    }

    static var vowelTeams: [EnglishSound] {
        allSounds.filter { $0.category == .vowelTeam }
    }
}

/// Static catalog for the 44 English sounds and their highlighted example words.
enum EnglishSoundCatalog {
    static let sounds: [EnglishSound] = vowels + consonants + vowelTeams

    static let vowels: [EnglishSound] = [
        sound("short_a", "Short /a/", .vowel, .ae, traceCharacter: "A",
              level1: ("Apple", [0, 1]),
              level2: [("Cat", [1, 1]), ("Hat", [1, 1]), ("Pan", [1, 1]), ("Bag", [1, 1]), ("After", [0, 1])],
              level3: [("Animal", [0, 1]), ("Family", [1, 1]), ("Candle", [1, 1]), ("Planet", [1, 1])]),
        sound("short_e", "Short /e/", .vowel, .eh, traceCharacter: "E",
              level1: ("Every", [0, 1]),
              level2: [("Pen", [1, 1]), ("Bed", [1, 1]), ("Red", [1, 1]), ("Ten", [1, 1]), ("Net", [1, 1])],
              level3: [("Letter", [1, 1]), ("Breakfast", [1, 1]), ("Remember", [1, 1]), ("Yellow", [1, 1])]),
        sound("short_i", "Short /i/", .vowel, .ih, traceCharacter: "I",
              level1: ("Busy", [3, 1]),
              level2: [("Bit", [1, 1]), ("Sit", [1, 1]), ("Hit", [1, 1]), ("Dig", [1, 1]), ("Fish", [1, 1])],
              level3: [("Interest", [0, 1]), ("English", [4, 1]), ("Kitten", [2, 1]), ("Little", [2, 1])]),
        sound("short_o", "Short /o/", .vowel, .ah, traceCharacter: "O",
              level1: ("Water", [1, 1]),
              level2: [("Hot", [1, 1]), ("Cot", [1, 1]), ("Pond", [1, 1]), ("Stop", [2, 1]), ("Rock", [2, 1])],
              level3: [("October", [0, 1]), ("Promise", [2, 1]), ("Honest", [0, 1]), ("Dollar", [1, 1])]),
        sound("short_u", "Short /u/", .vowel, .uh, traceCharacter: "U",
              level1: ("Under", [0, 1]),
              level2: [("Fun", [1, 1]), ("Bug", [1, 1]), ("But", [1, 1]), ("Cut", [1, 1]), ("Mud", [1, 1])],
              level3: [("Button", [1, 1]), ("Tunnel", [1, 1]), ("Summer", [1, 1]), ("Number", [1, 1])]),
        sound("long_o", "Long /o/", .vowel, .oh, traceCharacter: "O",
              level1: ("Over", [0, 1]),
              level2: [("Open", [0, 1]), ("Go", [1, 1]), ("No", [1, 1]), ("So", [1, 1]), ("Rose", [1, 1])],
              level3: [("Ocean", [0, 1]), ("Broken", [2, 1]), ("Golden", [2, 1])]),
        sound("long_a", "Long /a/", .vowel, .ay, traceCharacter: "A",
              level1: ("Make", [1, 1]),
              level2: [("Day", [1, 1]), ("Bay", [1, 1]), ("Say", [1, 1]), ("Rain", [1, 2]), ("Play", [1, 2])],
              level3: [("Flavor", [2, 1]), ("Rainbow", [1, 2]), ("Holiday", [2, 1]), ("Today", [2, 1])]),
        sound("long_i", "Long /i/", .vowel, .ie, traceCharacter: "I",
              level1: ("Lie", [0, 2]),
              level2: [("Night", [1, 3]), ("Bite", [1, 1]), ("Time", [1, 2]), ("Fly", [1, 2]), ("Pie", [0, 2])],
              level3: [("Light", [1, 3]), ("Firefly", [1, 3]), ("Science", [1, 2]), ("Diamond", [1, 2])]),
        sound("long_e", "Long /e/", .vowel, .i, traceCharacter: "E",
              level1: ("Feet", [1, 2]),
              level2: [("See", [1, 2]), ("Bee", [1, 2]), ("Tree", [1, 2]), ("Me", [1, 1]), ("We", [1, 1])],
              level3: [("Evening", [0, 1]), ("Speech", [2, 2]), ("Feast", [1, 2]), ("Sweet", [1, 2])]),
        sound("long_u", "Long /u/", .vowel, .u, traceCharacter: "U",
              level1: ("Unique", [0, 1]),
              level2: [("Rescue", [4, 1]), ("Unit", [0, 1]), ("Music", [1, 1]), ("Human", [1, 1])],
              level3: [("Computer", [1, 1]), ("Unicorn", [0, 1]), ("Umbrella", [0, 1]), ("Community", [5, 1])]),
        sound("long_oo", "Long /oo/", .vowel, .u, traceCharacter: "OO",
              level1: ("Blue", [2, 2]),
              level2: [("Flew", [2, 2]), ("Group", [2, 2]), ("Moon", [1, 2]), ("Food", [1, 2]), ("Room", [1, 2])],
              level3: [("School", [2, 2]), ("Bloom", [2, 2]), ("Spoon", [2, 2]), ("Cartoon", [2, 2])])
    ]

    static let consonants: [EnglishSound] = [
        sound("b", "/b/", .consonant, .b, traceCharacter: "B",
              level1: ("Bat", [0, 1]),
              level2: [("Bob", [0, 1]), ("Bus", [0, 1]), ("Bed", [0, 1]), ("Bear", [0, 1]), ("Ball", [0, 1])],
              level3: [("Baby", [0, 1]), ("Bubble", [0, 1]), ("Bubbles", [0, 1]), ("Bedroom", [0, 1]), ("Rabbit", [1, 1])]),
        sound("k", "/k/", .consonant, .k, traceCharacter: "K",
              level1: ("Care", [0, 1]),
              level2: [("Cat", [0, 1]), ("Kit", [0, 1]), ("Key", [0, 1]), ("Cup", [0, 1]), ("Come", [0, 1])],
              level3: [("Kindness", [0, 1]), ("Kitten", [0, 1]), ("Kitchen", [0, 1]), ("Blanket", [3, 1]), ("Rocket", [0, 1])]),
        sound("d", "/d/", .consonant, .d, traceCharacter: "D",
              level1: ("Add", [1, 2]),
              level2: [("Dog", [0, 1]), ("Dig", [0, 1]), ("Dad", [0, 1]), ("Dot", [0, 1]), ("Mud", [2, 1])],
              level3: [("Different", [0, 1]), ("Better", [2, 2]), ("Dragon", [0, 1]), ("Dinner", [2, 1]), ("Garden", [2, 1])]),
        sound("f", "/f/", .consonant, .f, traceCharacter: "F",
              level1: ("Fan", [0, 1]),
              level2: [("Fun", [0, 1]), ("Fog", [0, 1]), ("Fin", [0, 1]), ("Phone", [1, 2]), ("Often", [1, 1])],
              level3: [("Enough", [4, 2]), ("Flower", [0, 1]), ("Family", [0, 1]), ("Friend", [0, 1]), ("Finish", [0, 1])]),
        sound("g", "/g/", .consonant, .g, traceCharacter: "G",
              level1: ("Get", [0, 1]),
              level2: [("Go", [0, 1]), ("Gap", [0, 1]), ("Gum", [0, 1]), ("Guest", [0, 1]), ("Egg", [1, 2])],
              level3: [("Garden", [0, 1]), ("Guitar", [0, 1]), ("Giggle", [0, 1]), ("Golden", [0, 1]), ("Grocery", [0, 1])]),
        sound("h", "/h/", .consonant, .h, traceCharacter: "H",
              level1: ("Hat", [0, 1]),
              level2: [("Hop", [0, 1]), ("Hot", [0, 1]), ("Home", [0, 1]), ("Happy", [0, 1]), ("Who", [0, 1])],
              level3: [("House", [0, 1]), ("Holiday", [0, 1]), ("Hundred", [0, 1]), ("Hospital", [0, 1]), ("Happy", [0, 1])]),
        sound("j", "/j/", .consonant, .j, traceCharacter: "J",
              level1: ("Edge", [1, 2]),
              level2: [("Jump", [0, 1]), ("Jet", [0, 1]), ("Job", [0, 1]), ("Gem", [0, 1]), ("Gym", [0, 1])],
              level3: [("Jewelry", [0, 1]), ("Giraffe", [0, 1]), ("Jungle", [0, 1]), ("Jacket", [0, 1]), ("Enjoy", [2, 1])]),
        sound("l", "/l/", .consonant, .l, traceCharacter: "L",
              level1: ("Life", [0, 1]),
              level2: [("Lip", [0, 1]), ("Lap", [0, 1]), ("Log", [0, 1]), ("Lake", [0, 1]), ("Love", [0, 1])],
              level3: [("Laughter", [0, 1]), ("Little", [0, 1]), ("Yellow", [2, 1]), ("Pillow", [0, 1]), ("Family", [2, 1])]),
        sound("m", "/m/", .consonant, .m, traceCharacter: "M",
              level1: ("Map", [0, 1]),
              level2: [("Mom", [0, 1]), ("Ham", [1, 1]), ("Gum", [1, 1]), ("Some", [2, 1]), ("Sam", [1, 1])],
              level3: [("Summer", [2, 2]), ("Animal", [0, 1]), ("Family", [2, 1]), ("Monkey", [0, 1]), ("Tomato", [2, 1])]),
        sound("n", "/n/", .consonant, .n, traceCharacter: "N",
              level1: ("Nose", [0, 1]),
              level2: [("Nap", [0, 1]), ("Net", [0, 1]), ("Nut", [0, 1]), ("Funny", [2, 2]), ("Know", [1, 1])],
              level3: [("Banana", [2, 1]), ("Dinner", [2, 1]), ("Winter", [2, 1]), ("Planet", [2, 1]), ("Animal", [3, 1])]),
        sound("p", "/p/", .consonant, .p, traceCharacter: "P",
              level1: ("Pig", [0, 1]),
              level2: [("Pop", [0, 1]), ("Pup", [0, 1]), ("Pan", [0, 1]), ("Please", [0, 1]), ("Flip", [3, 1])],
              level3: [("Apple", [0, 1]), ("Happy", [0, 1]), ("People", [0, 1]), ("Pencil", [0, 1]), ("Purple", [0, 1])]),
        sound("r", "/r/", .consonant, .r, traceCharacter: "R",
              level1: ("Run", [0, 1]),
              level2: [("Red", [0, 1]), ("Rip", [0, 1]), ("Rain", [0, 1]), ("Ring", [0, 1]), ("Car", [1, 1])],
              level3: [("Carrot", [2, 2]), ("Rabbit", [0, 2]), ("Rainbow", [0, 2]), ("Brother", [3, 1]), ("Forest", [1, 1])]),
        sound("s", "/s/", .consonant, .s, traceCharacter: "S",
              level1: ("Sun", [0, 1]),
              level2: [("Sit", [0, 1]), ("Soap", [0, 1]), ("Seed", [0, 1]), ("Pace", [2, 1]), ("Bus", [1, 1])],
              level3: [("Circle", [0, 1]), ("Course", [4, 1]), ("Sister", [0, 1]), ("Sunshine", [0, 1]), ("Castle", [3, 1])]),
        sound("t", "/t/", .consonant, .t, traceCharacter: "T",
              level1: ("Top", [0, 1]),
              level2: [("Tap", [0, 1]), ("Ten", [0, 1]), ("Toy", [0, 1]), ("Tip", [0, 1]), ("Net", [2, 1])],
              level3: [("Watched", [2, 1]), ("Sweater", [4, 1]), ("Tiger", [0, 1]), ("Turtle", [0, 1]), ("Kitchen", [4, 2])]),
        sound("v", "/v/", .consonant, .v, traceCharacter: "V",
              level1: ("Five", [2, 1]),
              level2: [("Van", [0, 1]), ("Vet", [0, 1]), ("Vine", [0, 1]), ("Of", [1, 1]), ("Love", [2, 1])],
              level3: [("Seven", [2, 1]), ("River", [2, 1]), ("Travel", [3, 1]), ("Velvet", [0, 1]), ("Adventure", [2, 1])]),
        sound("w", "/w/", .consonant, .w, traceCharacter: "W",
              level1: ("Went", [0, 1]),
              level2: [("Wet", [0, 1]), ("Win", [0, 1]), ("Web", [0, 1]), ("Quick", [0, 2]), ("Why", [0, 1])],
              level3: [("Water", [0, 1]), ("Winter", [0, 1]), ("Window", [0, 1]), ("Weather", [0, 1]), ("Wonder", [0, 1])]),
        sound("y", "/y/", .consonant, .y, traceCharacter: "Y",
              level1: ("Yellow", [0, 1]),
              level2: [("Yes", [0, 1]), ("Yay", [0, 1]), ("Yak", [0, 1]), ("Yell", [0, 1]), ("Yard", [0, 1])],
              level3: [("Yogurt", [0, 1]), ("Beyond", [1, 1]), ("Canyon", [1, 1]), ("Royal", [1, 1])]),
        sound("z", "/z/", .consonant, .z, traceCharacter: "Z",
              level1: ("Zip", [0, 1]),
              level2: [("Zoo", [0, 1]), ("Zone", [0, 1]), ("His", [2, 1]), ("Buzz", [2, 1]), ("Fizz", [2, 1])],
              level3: [("Scissors", [3, 1]), ("Puzzle", [1, 1]), ("Frozen", [2, 1]), ("Amazing", [3, 1]), ("Lizard", [2, 1])]),
        sound("ch", "/ch/", .consonant, .ch, traceCharacter: "CH",
              level1: ("Chin", [0, 2]),
              level2: [("Chip", [0, 2]), ("Chat", [0, 2]), ("Chop", [0, 2]), ("Touch", [3, 2]), ("Lunch", [2, 2])],
              level3: [("Chicken", [0, 2]), ("Teacher", [0, 2]), ("Kitchen", [4, 2]), ("Chimney", [0, 2]), ("Lunchbox", [2, 2])]),
        sound("sh", "/sh/", .consonant, .sh, traceCharacter: "SH",
              level1: ("Ship", [0, 2]),
              level2: [("Shop", [0, 2]), ("Shoe", [0, 2]), ("Fish", [2, 2]), ("Shape", [0, 2]), ("Wish", [0, 2])],
              level3: [("Shadow", [0, 2]), ("Fishing", [0, 2]), ("Shower", [0, 2]), ("Treasure", [4, 2]), ("Washing", [0, 2])]),
        sound("th_voiceless", "Unvoiced /th/", .consonant, .theta, traceCharacter: "TH",
              level1: ("Thin", [0, 2]),
              level2: [("Math", [1, 2]), ("Path", [1, 2]), ("Bath", [1, 2]), ("Thick", [0, 2]), ("Tooth", [1, 2])],
              level3: [("Thursday", [0, 2]), ("Nothing", [3, 2]), ("Birthday", [3, 2]), ("Something", [3, 2]), ("Bathroom", [3, 2])]),
        sound("th_voiced", "Voiced /th/", .consonant, .eth, traceCharacter: "TH",
              level1: ("This", [0, 2]),
              level2: [("That", [0, 2]), ("Those", [0, 2]), ("Them", [0, 2]), ("Then", [0, 2]), ("They", [0, 2])],
              level3: [("These", [0, 2]), ("Mother", [3, 2]), ("Brother", [3, 2]), ("Weather", [3, 2]), ("Together", [1, 2])]),
        sound("hw", "/hw/", .consonant, .w, traceCharacter: "WH",
              level1: ("Whip", [0, 2]),
              level2: [("When", [0, 2]), ("White", [0, 2]), ("Whale", [0, 2]), ("What", [0, 2]), ("Whiz", [0, 2])],
              level3: [("Whisper", [0, 2]), ("Wheel", [0, 2]), ("Whistle", [0, 2])]),
        sound("ng", "/ng/", .consonant, .ng, traceCharacter: "NG",
              level1: ("Sing", [2, 2]),
              level2: [("Ring", [2, 2]), ("Long", [2, 2]), ("Bang", [2, 2]), ("King", [2, 2]), ("Bring", [3, 2])],
              level3: [("Going", [3, 2]), ("Singing", [3, 2]), ("Morning", [3, 2]), ("Springtime", [3, 2]), ("Humming", [3, 2])]),
        sound("nk", "/nk/", .consonant, .n, traceCharacter: "NK",
              level1: ("Sink", [2, 2]),
              level2: [("Pink", [2, 2]), ("Bank", [2, 2]), ("Blink", [3, 2]), ("Crank", [3, 2]), ("Think", [2, 2])],
              level3: [("Blanket", [3, 2]), ("Monkey", [2, 2]), ("Thankful", [2, 2]), ("Drink", [2, 2])]),
        sound("zh", "/zh/", .consonant, .zh, traceCharacter: "ZH",
              level1: ("Television", [6, 2]),
              level2: [("Beige", [2, 2]), ("Measure", [2, 2]), ("Vision", [2, 2]), ("Pleasure", [4, 2])],
              level3: [("Treasure", [4, 2]), ("Division", [3, 2]), ("Occasion", [4, 2])])
    ]

    static let vowelTeams: [EnglishSound] = [
        sound("ur", "/ur/", .vowelTeam, .er, traceCharacter: "UR",
              level1: ("Bird", [1, 2]),
              level2: [("Turn", [1, 2]), ("Her", [1, 2]), ("Fur", [1, 2]), ("Burn", [1, 2]), ("Hurt", [1, 2])],
              level3: [("Teacher", [2, 2]), ("Sister", [2, 2]), ("Winter", [2, 2]), ("Burger", [2, 2]), ("Circle", [2, 2])]),
        sound("ar", "/ar/", .vowelTeam, .ar, traceCharacter: "AR",
              level1: ("Park", [1, 2]),
              level2: [("Dark", [1, 2]), ("Car", [1, 2]), ("Star", [1, 2]), ("Far", [1, 2]), ("Jar", [1, 2])],
              level3: [("Garden", [1, 2]), ("Market", [1, 2]), ("Sparkle", [1, 2]), ("Harmony", [1, 2]), ("Carpet", [1, 2])]),
        sound("or", "/or/", .vowelTeam, .or_vowel, traceCharacter: "OR",
              level1: ("Fork", [1, 2]),
              level2: [("Pork", [1, 2]), ("Corn", [1, 2]), ("For", [1, 2]), ("Born", [1, 2]), ("Horn", [1, 2])],
              level3: [("Horse", [1, 2]), ("Forest", [1, 2]), ("Morning", [1, 2]), ("Important", [1, 2]), ("Storm", [1, 2])]),
        sound("oi", "/oi/", .vowelTeam, .oy, traceCharacter: "OI",
              level1: ("Boy", [1, 2]),
              level2: [("Toy", [1, 2]), ("Joy", [1, 2]), ("Coin", [1, 2]), ("Join", [1, 2]), ("Soil", [1, 2])],
              level3: [("Enjoy", [3, 2]), ("Oyster", [1, 2]), ("Cowboy", [2, 2]), ("Destroy", [1, 2])]),
        sound("ow", "/ow/", .vowelTeam, .ow, traceCharacter: "OW",
              level1: ("Owl", [0, 2]),
              level2: [("Ouch", [0, 2]), ("Cow", [0, 2]), ("Now", [0, 2]), ("How", [0, 2]), ("Town", [1, 2])],
              level3: [("Flower", [0, 2]), ("Outside", [0, 2]), ("Shower", [0, 2]), ("Mountain", [0, 2]), ("Cowboy", [0, 2])]),
        sound("oo_short", "/oo/", .vowelTeam, .u_short, traceCharacter: "OO",
              level1: ("Cool", [1, 2]),
              level2: [("Pull", [1, 2]), ("Book", [1, 2]), ("Look", [1, 2]), ("Good", [1, 2]), ("Foot", [1, 2])],
              level3: [("Cooking", [1, 2]), ("Wooden", [1, 2]), ("Cushion", [1, 2]), ("Goodbye", [1, 2]), ("Football", [1, 2])]),
        sound("aw", "/aw/", .vowelTeam, .aw, traceCharacter: "AW",
              level1: ("Jaw", [1, 2]),
              level2: [("Haul", [1, 2]), ("Saw", [1, 2]), ("Paw", [1, 2]), ("Raw", [1, 2]), ("Law", [1, 2])],
              level3: [("Draw", [2, 2]), ("Straw", [2, 2]), ("Awesome", [0, 2]), ("Caution", [1, 2]), ("Laundry", [1, 2])])
    ]

    private static func sound(
        _ id: String,
        _ displayName: String,
        _ category: EnglishSoundCategory,
        _ phoneme: Phoneme,
        traceCharacter: String,
        level1: (String, [Int]),
        level2: [(String, [Int])] = [],
        level3: [(String, [Int])] = []
    ) -> EnglishSound {
        EnglishSound(
            id: id,
            displayName: displayName,
            level1Example: example(level1),
            level2Examples: level2.map(example),
            level3Examples: level3.map(example),
            linkedPhoneme: phoneme,
            category: category,
            traceCharacter: traceCharacter
        )
    }

    private static func example(_ pair: (String, [Int])) -> EnglishExample {
        let (word, ranges) = pair
        let highlights = stride(from: 0, to: ranges.count, by: 2).map { index in
            SoundHighlight(start: ranges[index], length: ranges[index + 1])
        }
        return EnglishExample(word: word, highlights: highlights)
    }
}
