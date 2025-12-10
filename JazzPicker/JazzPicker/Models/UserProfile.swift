//
//  UserProfile.swift
//  JazzPicker
//

import Foundation

struct UserProfile: Codable, Sendable {
    let instrument: Instrument
    let displayName: String
    let createdAt: Date
    let updatedAt: Date

    init(instrument: Instrument, displayName: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.instrument = instrument
        self.displayName = displayName
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
        [
            "instrument": instrument.rawValue,
            "displayName": displayName,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}
