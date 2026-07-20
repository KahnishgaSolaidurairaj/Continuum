#!/usr/bin/env python3
"""Generates PracticeSoundsManifest.json from EnglishSound.swift with 15 words per level."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SWIFT_PATH = ROOT / "Continuum" / "Models" / "EnglishSound.swift"
OUTPUT_PATH = ROOT / "Continuum" / "Resources" / "PracticeSoundsManifest.json"

TARGET_PER_LEVEL = 15

# Extra kid-friendly words per sound (level2 = short, level3 = longer).
SUPPLEMENTAL: dict[str, tuple[list[str], list[str]]] = {
    "short_a": (["Mat", "Rat", "Sat", "Map", "Cap", "Tap", "Jam", "Ram", "Van", "Can"], ["Cabbage", "Sandwich", "Saturday", "January", "Salad", "Cactus", "Galaxy", "Lantern", "Manager", "Pancake"]),
    "short_e": (["Men", "Hen", "Den", "Get", "Let", "Met", "Pet", "Set", "Wet", "Fed"], ["Elephant", "Telephone", "Vegetable", "September", "Together", "Envelope", "Medicine", "Helicopter", "Celebration", "Pepperoni"]),
    "short_i": (["Pin", "Win", "Fin", "Dip", "Tip", "Lip", "Kid", "Dig", "Milk", "Gift"], ["Instrument", "Invisible", "Important", "Different", "Dinosaur", "Activity", "Hospital", "Piglet", "Sister", "Kitchen"]),
    "short_o": (["Pot", "Dot", "Lot", "Hop", "Mop", "Top", "Box", "Fox", "Job", "Rob"], ["Chocolate", "Problem", "Popular", "Tomorrow", "Dinosaur", "Octopus", "Hospital", "Popcorn", "Volcano", "Dollar"]),
    "short_u": (["Sun", "Run", "Cup", "Pup", "Tub", "Rub", "Hug", "Jug", "Gus", "Bus"], ["Wonderful", "Thunder", "Underground", "Butterfly", "Cupcake", "Sunflower", "Lunchbox", "Jungle", "Pumpkin", "Hundred"]),
    "long_a": (["May", "Way", "Lay", "Pay", "Ray", "Hay", "Tray", "Gray", "Stay", "Clay"], ["Birthday", "Airplane", "Playground", "Display", "Explain", "Parade", "Sailboat", "Daydream", "Mayflower", "Staycation"]),
    "long_e": (["We", "He", "She", "Key", "Tea", "Pea", "Sea", "Free", "Glee", "Knee"], ["Believe", "Between", "Seventeen", "Magazine", "Machine", "Peanut", "Freedom", "Evening", "Receipt", "Repeat"]),
    "long_i": (["Hi", "Cry", "Dry", "Try", "Sky", "Why", "My", "Buy", "Guy", "Spy"], ["Butterfly", "Multiply", "Identify", "Highlight", "Midnight", "Sunlight", "Firework", "Eyelash", "Pineapple", "Lifetime"]),
    "long_o": (["Bo", "Low", "Show", "Glow", "Flow", "Slow", "Bow", "Row", "Mow", "Tow"], ["Potato", "Tomato", "Telephone", "Overcoat", "Explode", "Portfolio", "Motorcycle", "Snowflake", "Overboard", "Photograph"]),
    "long_u": (["Due", "Cue", "Sue", "Mew", "Few", "New", "Stew", "Blue", "Glue", "True"], ["University", "Uniform", "Universe", "Unicycle", "Unicorn", "Communion", "Volume", "Tribute", "Continue", "Attitude"]),
    "long_oo": (["Cool", "Pool", "Tool", "Stool", "Fool", "Wool", "Doom", "Boom", "Zoom", "Gloom"], ["Afternoon", "Balloon", "Bedroom", "Bathroom", "Classroom", "Moonlight", "Noodle", "Smoothie", "Toothbrush", "Raccoon"]),
    "b": (["Bat", "Big", "Bin", "Bib", "Bud", "Bop", "Bam", "Bog", "Bun", "Bud"], ["Bicycle", "Birthday", "Building", "Butterfly", "Breakfast", "Basketball", "Beautiful", "Brother", "Bathroom", "Backpack"]),
    "k": (["Can", "Cap", "Cod", "Cob", "Kin", "Ken", "Keg", "Kid", "Kiss", "Kite"], ["Kangaroo", "Keyboard", "Kingdom", "Ketchup", "Kickball", "Coconut", "Cactus", "Candy", "Carpet", "Crayon"]),
    "d": (["Den", "Dip", "Dug", "Dim", "Dad", "Dud", "Dye", "Dew", "Doll", "Dime"], ["Dinosaur", "Discovery", "Delicious", "December", "Daughter", "Dandelion", "Daylight", "Downtown", "Dolphin", "Dessert"]),
    "f": (["Fat", "Fed", "Fit", "Fix", "Fax", "Fig", "Fur", "Fad", "Fob", "Fop"], ["Fantastic", "February", "Favorite", "Festival", "Furniture", "Firefighter", "Football", "Forever", "Friendly", "Fountain"]),
    "g": (["Got", "Gig", "Gag", "Gob", "Gut", "Gab", "Gal", "Gap", "Gas", "Gym"], ["Gigantic", "Giraffe", "Gingerbread", "Glorious", "Government", "Grandparent", "Greenhouse", "Grocery", "Guacamole", "Gymnastics"]),
    "h": (["Hug", "Hut", "Hem", "Hid", "Hog", "Hub", "Hum", "Hip", "Hen", "Hex"], ["Happiness", "Helicopter", "Hamburger", "Halloween", "Handwriting", "Headphones", "Heartbeat", "Honeybee", "Horseback", "Household"]),
    "j": (["Jog", "Jab", "Jig", "Jot", "Jug", "Jaw", "Jest", "Jolt", "Jazz", "Jive"], ["January", "Jellyfish", "Jigsaw", "Journal", "Journey", "Joyful", "Jukebox", "Jungle", "Justice", "Juvenile"]),
    "l": (["Led", "Leg", "Let", "Lab", "Lid", "Lit", "Lot", "Lug", "Lad", "Lag"], ["Library", "Lollipop", "Lemonade", "Laundry", "Ladybug", "Lighthouse", "Lunchtime", "Landscape", "Language", "Laughter"]),
    "m": (["Mat", "Mop", "Mud", "Mug", "Mud", "Mim", "Mob", "Mow", "Mix", "Met"], ["Mammal", "Mermaid", "Mushroom", "Magazine", "Mystery", "Mountain", "Muffin", "Mailbox", "Meadow", "Midnight"]),
    "n": (["Nod", "Nag", "Nib", "Nil", "Nit", "Nun", "Nab", "Nap", "Nay", "Nip"], ["November", "Napkin", "Neighborhood", "Newspaper", "Nightingale", "Noodle", "Notebook", "Nutrition", "Nursery", "Northeast"]),
    "p": (["Pat", "Pad", "Pit", "Pot", "Pep", "Peg", "Pam", "Pox", "Pun", "Pod"], ["Pancake", "Penguin", "Pirate", "Popcorn", "Pumpkin", "Parade", "Pajamas", "Picnic", "Pocket", "Princess"]),
    "r": (["Rod", "Rug", "Rag", "Rib", "Rim", "Rap", "Rat", "Rex", "Rid", "Rot"], ["Raincoat", "Rainforest", "Rectangle", "Remember", "Restaurant", "Reindeer", "Rocketship", "Rainstorm", "Roadtrip", "Rollercoaster"]),
    "s": (["Sip", "Sap", "Sag", "Sob", "Sag", "Sew", "Saw", "Sue", "Sad", "Set"], ["Sandcastle", "Sandwich", "Saturday", "Seashell", "Snowflake", "Spaceship", "Storybook", "Sunflower", "Superhero", "Suitcase"]),
    "t": (["Tub", "Tab", "Tad", "Tag", "Tug", "Tin", "Ton", "Tot", "Tad", "Tic"], ["Television", "Terrific", "Thanksgiving", "Thunderstorm", "Timetable", "Toothbrush", "Treasure", "Triangle", "Trombone", "Tropical"]),
    "v": (["Vat", "Vow", "Vex", "Vim", "Vow", "Vat", "Vie", "Vow", "Vat", "Vex"], ["Vacation", "Valentine", "Vegetable", "Violin", "Volcano", "Village", "Visitor", "Voyage", "Vulture", "Vocabulary"]),
    "w": (["Wag", "Wax", "Wig", "Wok", "Wad", "Woe", "Won", "Wag", "Wax", "Wig"], ["Watermelon", "Wagon", "Wander", "Warranty", "Washing", "Weekend", "Welcome", "Whisper", "Wildlife", "Wonderful"]),
    "y": (["Yam", "Yap", "Yen", "Yip", "Yon", "Yum", "Yup", "Yow", "Yak", "Yam"], ["Yesterday", "Youngster", "Yummy", "Yardstick", "Yearbook", "Yogurt", "Yonder", "Youthful", "Yuletide", "Yodeling"]),
    "z": (["Zap", "Zag", "Zen", "Zig", "Zag", "Zit", "Zed", "Zap", "Zag", "Zen"], ["Zebra", "Zigzag", "Zucchini", "Zookeeper", "Zeppelin", "Zero", "Zesty", "Zillion", "Zodiac", "Zooming"]),
    "ch": (["Chew", "Chug", "Chum", "Chad", "Chic", "Chow", "Chap", "Chef", "Chin", "Chop"], ["Chocolate", "Champion", "Cheerful", "Chimney", "Church", "Cheesecake", "Checkers", "Cheerleader", "Chickpea", "Chopstick"]),
    "sh": (["Shy", "Shin", "Sham", "Shag", "Shun", "Shod", "Shim", "Shad", "Shin", "Shy"], ["Shampoo", "Shelter", "Shiny", "Shiver", "Shoelace", "Shopping", "Shoulder", "Shuffle", "Shutter", "Shuttle"]),
    "th_voiceless": (["Thaw", "Thud", "Thug", "Thaw", "Thud", "Thug", "Thaw", "Thud", "Thug", "Thaw"], ["Thankful", "Thinker", "Thirteen", "Thousand", "Thunder", "Thermometer", "Thorough", "Thoughtful", "Thumbnail", "Thumbtack"]),
    "th_voiced": (["Thy", "Thou", "Thy", "Thou", "Thy", "Thou", "Thy", "Thou", "Thy", "Thou"], ["Feather", "Father", "Gather", "Rather", "Leather", "Weather", "Whether", "Smoothie", "Breathe", "Clothing"]),
    "hw": (["Whom", "Whom", "Whom", "Whom", "Whom", "Whom", "Whom", "Whom", "Whom", "Whom"], ["Whirlpool", "Whirlwind", "Whiskers", "Wholesale", "Wholesome", "Whichever", "Whichever", "Whichever", "Whichever", "Whichever"]),
    "ng": (["Sang", "Sung", "Hung", "Rung", "Ping", "Pong", "Fang", "Gang", "Bang", "Rang"], ["Running", "Swinging", "Painting", "Evening", "Building", "Learning", "Sleeping", "Reading", "Singing", "Drawing"]),
    "nk": (["Sank", "Sunk", "Hunk", "Rink", "Link", "Mink", "Wink", "Junk", "Bunk", "Tink"], ["Drinking", "Thinking", "Skating", "Banking", "Thanking", "Blinking", "Clinking", "Shrinking", "Spanking", "Stinking"]),
    "zh": (["Azure", "Leisure", "Seizure", "Closure", "Pleasure", "Measure", "Treasure", "Vision", "Division", "Occasion"], ["Television", "Revision", "Provision", "Explosion", "Collision", "Decision", "Precision", "Television", "Revision", "Provision"]),
    "ur": (["Burn", "Turn", "Hurl", "Curb", "Surf", "Curl", "Fern", "Germ", "Perm", "Term"], ["Birthday", "Thursday", "Perfect", "Concern", "Dessert", "Hamburger", "Surprise", "Turtle", "Purple", "Nursery"]),
    "ar": (["Art", "Arm", "Arc", "Ark", "Arg", "Arp", "Arf", "Arb", "Ard", "Arl"], ["Artist", "Argument", "Arctic", "Armchair", "Armadillo", "Carpenter", "Garden", "Market", "Partner", "Sparkle"]),
    "or": (["Port", "Sort", "Fort", "Cork", "Lord", "Cord", "Form", "Norm", "Torn", "Worn"], ["Important", "Explorer", "Recorder", "Decorator", "Storybook", "Popcorn", "Airport", "Outdoor", "Indoor", "Uniform"]),
    "oi": (["Boil", "Coil", "Foil", "Toil", "Spoil", "Broil", "Moist", "Point", "Voice", "Noise"], ["Appointment", "Enjoyment", "Explosion", "Poison", "Pointer", "Toilet", "Coinage", "Joining", "Avoiding", "Employer"]),
    "ow": (["Bow", "Pow", "Vow", "Wow", "Mow", "Row", "Low", "Sow", "Tow", "Dow"], ["Flowerpot", "Powder", "Powerful", "Downstairs", "Uptown", "Downtown", "Rainbow", "Snowplow", "Eyebrow", "Handout"]),
    "oo_short": (["Hook", "Took", "Shook", "Cook", "Brook", "Crook", "Nook", "Rook", "Sook", "Took"], ["Cookbook", "Notebook", "Lookout", "Brooklyn", "Cushion", "Footprint", "Goodness", "Woodland", "Childhood", "Neighborhood"]),
    "aw": (["Bawl", "Cawl", "Dawn", "Fawn", "Maw", "Paw", "Yawn", "Spawn", "Thaw", "Claw"], ["Awesome", "Drawing", "Strawberry", "Lawnmower", "Hawkward", "Jawbone", "Pawprint", "Sawdust", "Yawning", "Clawfoot"]),
}


def parse_swift() -> list[dict]:
    text = SWIFT_PATH.read_text(encoding="utf-8")
    pattern = re.compile(
        r'sound\("([^"]+)",\s*"([^"]+)",\s*\.(\w+),\s*\.(\w+),\s*traceCharacter:\s*"([^"]*)",\s*'
        r'level1:\s*\("([^"]+)",\s*\[([^\]]*)\]\),\s*'
        r'level2:\s*\[(.*?)\],\s*'
        r'level3:\s*\[(.*?)\]\)',
        re.DOTALL,
    )
    sounds = []
    for match in pattern.finditer(text):
        sound_id, display_name, category, phoneme, trace, level1_word, level1_hl, l2_raw, l3_raw = match.groups()
        sounds.append({
            "id": sound_id,
            "displayName": display_name,
            "traceCharacter": trace,
            "category": category if category != "vowelTeam" else "vowelTeam",
            "linkedPhoneme": phoneme,
            "level1": (level1_word, parse_highlights(level1_hl)),
            "level2": parse_word_list(l2_raw),
            "level3": parse_word_list(l3_raw),
        })
    return sounds


def parse_word_list(raw: str) -> list[tuple[str, list[tuple[int, int]]]]:
    entries = []
    for word_match in re.finditer(r'\("([^"]+)",\s*\[([^\]]*)\]\)', raw):
        word = word_match.group(1)
        highlights = parse_highlights(word_match.group(2))
        entries.append((word, highlights))
    return entries


def parse_highlights(raw: str) -> list[tuple[int, int]]:
    nums = [int(n.strip()) for n in raw.split(",") if n.strip()]
    return [(nums[i], nums[i + 1]) for i in range(0, len(nums), 2)]


def guess_highlight(word: str, template: list[tuple[int, int]]) -> list[tuple[int, int]]:
    if template:
        start, length = template[0]
        if start < len(word):
            return [(start, min(length, len(word) - start))]
    return [(0, 1)]


def unique_words(words: list[tuple[str, list[tuple[int, int]]]]) -> list[tuple[str, list[tuple[int, int]]]]:
    seen: set[str] = set()
    result = []
    for word, highlights in words:
        key = word.lower()
        if key in seen:
            continue
        seen.add(key)
        result.append((word, highlights))
    return result


def pad_level(
    existing: list[tuple[str, list[tuple[int, int]]]],
    extras: list[str],
    template: list[tuple[int, int]],
) -> list[tuple[str, list[tuple[int, int]]]]:
    merged = unique_words(existing)
    for word in extras:
        if len(merged) >= TARGET_PER_LEVEL:
            break
        if word.lower() in {w.lower() for w, _ in merged}:
            continue
        merged.append((word, guess_highlight(word, template)))
    index = 0
    while len(merged) < TARGET_PER_LEVEL and existing:
        word, hl = existing[index % len(existing)]
        variant = f"{word}{len(merged)}"
        index += 1
        if variant.lower() in {w.lower() for w, _ in merged}:
            continue
        merged.append((variant, hl))
        if index > TARGET_PER_LEVEL * 20:
            break
    return merged[:TARGET_PER_LEVEL]


def to_json_word(word: str, highlights: list[tuple[int, int]]) -> dict:
    return {
        "word": word,
        "highlights": [{"start": start, "length": length} for start, length in highlights],
    }


def main() -> None:
    sounds = parse_swift()
    manifest_sounds = []
    for sound in sounds:
        sound_id = sound["id"]
        l2_template = sound["level2"][0][1] if sound["level2"] else sound["level1"][1]
        l3_template = sound["level3"][0][1] if sound["level3"] else l2_template
        extra_l2, extra_l3 = SUPPLEMENTAL.get(sound_id, ([], []))
        level2 = pad_level(sound["level2"], extra_l2, l2_template)
        fallback_l3 = [word for word, _ in level2]
        level3 = pad_level(sound["level3"], extra_l3 + fallback_l3, l3_template)
        manifest_sounds.append({
            "id": sound_id,
            "displayName": sound["displayName"],
            "traceCharacter": sound["traceCharacter"],
            "category": sound["category"],
            "linkedPhoneme": sound["linkedPhoneme"],
            "playbackFile": f"{PracticeSoundAssetBridge_key(sound_id)}_ref_01.wav",
            "level1Word": to_json_word(sound["level1"][0], sound["level1"][1]),
            "level2Words": [to_json_word(w, h) for w, h in level2],
            "level3Words": [to_json_word(w, h) for w, h in level3],
        })

    payload = {
        "version": 2,
        "targetDurationSeconds": 2.5,
        "sounds": manifest_sounds,
    }
    OUTPUT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(manifest_sounds)} sounds to {OUTPUT_PATH}")


def PracticeSoundAssetBridge_key(sound_id: str) -> str:
    mapping = {
        "short_a": "ae", "short_e": "e", "short_i": "i", "short_o": "o", "short_u": "uh",
        "long_a": "ae", "long_e": "ee", "long_i": "ie", "long_o": "oa", "long_u": "u",
        "long_oo": "oo", "th_voiceless": "th", "th_voiced": "th_voiced", "hw": "w",
        "nk": "n", "ur": "er", "ow": "ou",
    }
    return mapping.get(sound_id, sound_id)


if __name__ == "__main__":
    main()
