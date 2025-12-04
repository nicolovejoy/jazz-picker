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
