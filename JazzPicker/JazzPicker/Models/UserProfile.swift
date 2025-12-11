//
//  UserProfile.swift
//  JazzPicker
//

import Foundation

struct UserProfile: Codable, Sendable {
    let instrument: Instrument
    let displayName: String
    let preferredKeys: [String: String]?  // songTitle -> concertKey (sparse: only non-default keys)
    let createdAt: Date
    let updatedAt: Date

    init(instrument: Instrument, displayName: String, preferredKeys: [String: String]? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.instrument = instrument
        self.displayName = displayName
        self.preferredKeys = preferredKeys
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
        return data
    }
}
