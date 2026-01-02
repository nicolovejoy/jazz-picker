//
//  TimeSignature.swift
//  JazzPicker
//
//  Time signature enum for metronome meter selection.
//

import Foundation

enum TimeSignature: String, CaseIterable, Identifiable, Codable {
    case twoTwo = "2/2"
    case twoFour = "2/4"
    case threeFour = "3/4"
    case fourFour = "4/4"
    case fiveFour = "5/4"
    case sixFour = "6/4"
    case threeEight = "3/8"
    case fiveEight = "5/8"
    case sixEight = "6/8"
    case sevenEight = "7/8"
    case nineEight = "9/8"
    case twelveEight = "12/8"

    var id: String { rawValue }

    var beatsPerMeasure: Int {
        switch self {
        case .twoTwo: return 2
        case .twoFour: return 2
        case .threeFour: return 3
        case .fourFour: return 4
        case .fiveFour: return 5
        case .sixFour: return 6
        case .threeEight: return 3
        case .fiveEight: return 5
        case .sixEight: return 6
        case .sevenEight: return 7
        case .nineEight: return 9
        case .twelveEight: return 12
        }
    }

    var noteValue: Int {
        switch self {
        case .twoTwo: return 2
        case .twoFour, .threeFour, .fourFour, .fiveFour, .sixFour: return 4
        case .threeEight, .fiveEight, .sixEight, .sevenEight, .nineEight, .twelveEight: return 8
        }
    }

    /// Compound meters (6/8, 9/8, 12/8) are typically felt in larger beats
    var isCompound: Bool {
        switch self {
        case .sixEight, .nineEight, .twelveEight: return true
        default: return false
        }
    }

    /// For compound meters, the number of main beats felt (e.g., 6/8 = 2, 9/8 = 3)
    var feltBeats: Int {
        switch self {
        case .sixEight: return 2
        case .nineEight: return 3
        case .twelveEight: return 4
        default: return beatsPerMeasure
        }
    }

    /// Create from a string like "4/4" or "6/8"
    init?(from string: String) {
        if let sig = TimeSignature(rawValue: string) {
            self = sig
        } else {
            return nil
        }
    }

    /// Display name (same as rawValue for now)
    var displayName: String { rawValue }
}
