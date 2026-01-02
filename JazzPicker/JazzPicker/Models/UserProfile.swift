//
//  UserProfile.swift
//  JazzPicker
//

import Foundation

/// Per-song metronome settings stored in user profile
struct SongMetronomeSettings: Codable, Sendable, Equatable {
    let bpm: Int?
    let timeSignature: String?

    init(bpm: Int? = nil, timeSignature: String? = nil) {
        self.bpm = bpm
        self.timeSignature = timeSignature
    }

    init?(from data: [String: Any]) {
        let bpm = data["bpm"] as? Int
        let timeSignature = data["timeSignature"] as? String
        // Only create if at least one field is set
        guard bpm != nil || timeSignature != nil else { return nil }
        self.bpm = bpm
        self.timeSignature = timeSignature
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [:]
        if let bpm = bpm { data["bpm"] = bpm }
        if let timeSignature = timeSignature { data["timeSignature"] = timeSignature }
        return data
    }

    /// Returns true if no settings are actually set
    var isEmpty: Bool {
        bpm == nil && timeSignature == nil
    }
}

struct UserProfile: Codable, Sendable {
    let instrument: Instrument
    let displayName: String
    let preferredKeys: [String: String]?  // songTitle -> concertKey (sparse: only non-default keys)
    let preferredOctaveOffsets: [String: Int]?  // songTitle -> octaveOffset (sparse: only non-zero)
    let metronomeSettings: [String: SongMetronomeSettings]?  // songTitle -> metronome settings (sparse)
    let groups: [String]?  // array of group IDs
    let lastUsedGroupId: String?  // default group for setlist creation
    let createdAt: Date
    let updatedAt: Date

    init(instrument: Instrument, displayName: String, preferredKeys: [String: String]? = nil,
         preferredOctaveOffsets: [String: Int]? = nil,
         metronomeSettings: [String: SongMetronomeSettings]? = nil,
         groups: [String]? = nil, lastUsedGroupId: String? = nil,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.instrument = instrument
        self.displayName = displayName
        self.preferredKeys = preferredKeys
        self.preferredOctaveOffsets = preferredOctaveOffsets
        self.metronomeSettings = metronomeSettings
        self.groups = groups
        self.lastUsedGroupId = lastUsedGroupId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(from data: [String: Any]) {
        guard let instrumentString = data["instrument"] as? String,
              let instrument = Instrument(rawValue: instrumentString),
              let displayName = data["displayName"] as? String else {
            return nil
        }

        self.instrument = instrument
        self.displayName = displayName
        self.preferredKeys = data["preferredKeys"] as? [String: String]
        self.preferredOctaveOffsets = data["preferredOctaveOffsets"] as? [String: Int]
        self.groups = data["groups"] as? [String]
        self.lastUsedGroupId = data["lastUsedGroupId"] as? String

        // Parse metronome settings
        if let metroData = data["metronomeSettings"] as? [String: [String: Any]] {
            var settings: [String: SongMetronomeSettings] = [:]
            for (songTitle, songData) in metroData {
                if let songSettings = SongMetronomeSettings(from: songData) {
                    settings[songTitle] = songSettings
                }
            }
            self.metronomeSettings = settings.isEmpty ? nil : settings
        } else {
            self.metronomeSettings = nil
        }

        // Handle Firestore Timestamps
        if let timestamp = data["createdAt"] as? Date {
            self.createdAt = timestamp
        } else {
            self.createdAt = Date()
        }

        if let timestamp = data["updatedAt"] as? Date {
            self.updatedAt = timestamp
        } else {
            self.updatedAt = Date()
        }
    }

    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "instrument": instrument.rawValue,
            "displayName": displayName,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let preferredKeys = preferredKeys {
            data["preferredKeys"] = preferredKeys
        }
        if let preferredOctaveOffsets = preferredOctaveOffsets {
            data["preferredOctaveOffsets"] = preferredOctaveOffsets
        }
        if let metronomeSettings = metronomeSettings {
            var metroData: [String: [String: Any]] = [:]
            for (songTitle, settings) in metronomeSettings {
                metroData[songTitle] = settings.toFirestoreData()
            }
            data["metronomeSettings"] = metroData
        }
        if let groups = groups {
            data["groups"] = groups
        }
        if let lastUsedGroupId = lastUsedGroupId {
            data["lastUsedGroupId"] = lastUsedGroupId
        }
        return data
    }
}
