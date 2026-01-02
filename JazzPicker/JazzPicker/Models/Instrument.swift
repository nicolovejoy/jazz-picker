//
//  Instrument.swift
//  JazzPicker
//

import Foundation

enum Instrument: String, CaseIterable, Codable, Identifiable, Sendable {
    case piano
    case guitar
    case trumpet
    case clarinet
    case tenorSax = "tenor-sax"
    case sopranoSax = "soprano-sax"
    case altoSax = "alto-sax"
    case bariSax = "bari-sax"
    case bass
    case trombone

    var id: String { rawValue }

    var label: String {
        switch self {
        case .piano: "Piano"
        case .guitar: "Guitar"
        case .trumpet: "Trumpet"
        case .clarinet: "Clarinet"
        case .tenorSax: "Tenor Sax"
        case .sopranoSax: "Soprano Sax"
        case .altoSax: "Alto Sax"
        case .bariSax: "Bari Sax"
        case .bass: "Bass"
        case .trombone: "Trombone"
        }
    }

    var transposition: Transposition {
        switch self {
        case .piano, .guitar, .bass, .trombone:
            return .C
        case .trumpet, .clarinet, .tenorSax, .sopranoSax:
            return .Bb
        case .altoSax, .bariSax:
            return .Eb
        }
    }

    var clef: Clef {
        switch self {
        case .bass, .trombone:
            return .bass
        default:
            return .treble
        }
    }

    // MARK: - Groupings for UI

    /// Instrument grouping for picker UI. Will become data-driven when instruments are first-class objects.
    struct Group: Identifiable {
        let id: String
        let label: String
        let instruments: [Instrument]
    }

    static let groups: [Group] = [
        Group(id: "concert", label: "Concert Pitch", instruments: [.piano, .guitar]),
        Group(id: "bb", label: "B♭ Instruments", instruments: [.trumpet, .clarinet, .tenorSax, .sopranoSax]),
        Group(id: "eb", label: "E♭ Instruments", instruments: [.altoSax, .bariSax]),
        Group(id: "bass", label: "Bass Clef", instruments: [.bass, .trombone])
    ]
}

enum Transposition: String, Codable, Sendable {
    case C
    case Bb
    case Eb
}

enum Clef: String, Codable, Sendable {
    case treble
    case bass
}
