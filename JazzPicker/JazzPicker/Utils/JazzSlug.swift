//
//  JazzSlug.swift
//  JazzPicker
//

import Foundation

enum JazzSlug {
    // Word pools for each position in the slug
    private static let pool1: [String] = [
        // Feels
        "blue", "smoky", "mellow", "hot", "slick", "velvet", "midnight", "golden",
        "silver", "deep", "high", "low", "fast", "slow", "soft", "loud",
        "dark", "bright", "warm", "cool", "sweet", "bitter", "salty", "spicy",
        "smooth", "rough", "sharp", "flat", "round", "square", "tight", "loose",
        "funky", "groovy", "swinging", "burning", "cooking", "simmering", "boiling", "steaming",
        "lazy", "easy", "breezy", "hazy", "crazy", "wild", "calm", "zen",
        // Styles
        "bebop", "swing", "modal", "fusion", "latin", "bossa", "free",
        "hardbop", "soul", "funk", "gypsy", "dixie", "ragtime", "stride",
        "avant", "post", "neo", "acid", "nu", "ethio", "afro", "euro",
        // Times
        "dawn", "dusk", "noon", "night", "evening", "morning", "twilight", "sunset",
        "spring", "summer", "autumn", "winter", "monday", "friday", "saturday", "sunday",
        "early", "late", "after", "before", "during", "between", "around", "about",
    ]

    private static let pool2: [String] = [
        // Musicians
        "monk", "bird", "trane", "miles", "duke", "dizzy", "mingus", "ella",
        "billie", "oscar", "herbie", "wayne", "sonny", "dexter", "cannonball", "art",
        "max", "clifford", "kenny", "wes", "joe", "stan", "dave", "bill",
        "chick", "keith", "pat", "jaco", "tony", "elvin", "philly", "ron",
        "mccoy", "horace", "ahmad", "bud", "red", "hank", "lee", "freddie",
        // Instruments
        "keys", "bass", "drums", "horn", "sax", "trumpet", "guitar", "piano",
        "rhodes", "wurli", "organ", "synth", "vibes", "marimba", "congas", "bongos",
        "trombone", "flute", "clarinet", "alto", "tenor", "bari", "soprano", "cornet",
        "upright", "standup", "fender", "gibson", "archtop", "hollow", "snare", "kick",
        "hihat", "ride", "crash", "cymbal", "stick", "brush", "mallet", "pedal",
        // Things
        "note", "tone", "sound", "tune", "song", "piece", "number", "track",
        "record", "album", "disc", "vinyl", "wax", "tape", "mix", "master",
        "solo", "duo", "trio", "quartet", "quintet", "sextet", "septet", "octet",
        "band", "combo", "group", "ensemble", "unit", "crew", "cats", "players",
        "dream", "memory", "story", "tale", "legend", "myth", "spirit",
        "love", "heart", "mind", "body", "hand", "finger", "ear", "eye",
    ]

    private static let pool3: [String] = [
        // Terms
        "tritone", "voicing", "changes", "head", "comp", "lick", "turnaround", "vamp",
        "bridge", "coda", "intro", "outro", "chorus", "verse", "tag", "shout",
        "break", "fill", "riff", "motif", "phrase", "line", "run", "arpeggio",
        "chord", "scale", "mode", "groove", "pocket", "feel", "time", "beat",
        "rhythm", "pulse", "accent", "ghost", "bend", "slide", "hammer", "pull",
        "slap", "pop", "strum", "pick", "bow", "pluck", "blow", "reed",
        "chart", "lead", "sheet", "fake", "real", "book", "gig", "set",
        "jam", "session", "sit", "shed", "woodshed", "practice", "chops", "ears",
        // Actions
        "swing", "bounce", "float", "glide", "soar", "fly", "jump", "leap",
        "walk", "strut", "stroll", "cruise", "coast", "drift", "flow", "stream",
        "sing", "hum", "whistle", "snap", "clap", "tap", "stomp", "dance",
        "play", "hit", "strike", "touch", "move",
        // Places
        "village", "harlem", "birdland", "mintons", "bluenote", "vanguard", "iridium", "apollo",
        "savoy", "cotton", "club", "lounge", "joint", "spot", "room", "basement",
        "corner", "alley", "street", "avenue", "lane", "way", "drive", "road",
        "paris", "tokyo", "berlin", "rio", "havana", "chicago", "orleans", "memphis",
    ]

    static func generate() -> String {
        let word1 = pool1.randomElement()!
        let word2 = pool2.randomElement()!
        let word3 = pool3.randomElement()!
        return "\(word1)-\(word2)-\(word3)"
    }

    static func isValid(_ slug: String) -> Bool {
        let parts = slug.lowercased().split(separator: "-")
        return parts.count == 3 && parts.allSatisfy { $0.allSatisfy { $0.isLetter } }
    }

    static func normalize(_ input: String) -> String {
        input.lowercased().trimmingCharacters(in: .whitespaces)
    }
}
