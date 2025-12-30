//
//  Song.swift
//  JazzPicker
//

import Foundation

struct Song: Codable, Identifiable, Hashable, Sendable {
    var id: String { title }

    let title: String
    let defaultKey: String
    let composer: String?
    let lowNoteMidi: Int?
    let highNoteMidi: Int?
    let scoreId: String?
    let partName: String?

    // Tempo metadata
    let tempoStyle: String?
    let tempoSource: String?
    let tempoBpm: Int?
    let tempoNoteValue: Int?
    let timeSignature: String?

    enum CodingKeys: String, CodingKey {
        case title
        case defaultKey = "default_key"
        case composer
        case lowNoteMidi = "low_note_midi"
        case highNoteMidi = "high_note_midi"
        case scoreId = "score_id"
        case partName = "part_name"
        case tempoStyle = "tempo_style"
        case tempoSource = "tempo_source"
        case tempoBpm = "tempo_bpm"
        case tempoNoteValue = "tempo_note_value"
        case timeSignature = "time_signature"
    }
}

struct CatalogResponse: Codable, Sendable {
    let songs: [Song]
    let total: Int
}

struct GenerateResponse: Codable, Sendable {
    let url: String
    let cached: Bool
    let generationTimeMs: Int?
    let crop: CropBounds?
    let octaveOffset: Int?
    let includeVersion: String?

    enum CodingKeys: String, CodingKey {
        case url
        case cached
        case generationTimeMs = "generation_time_ms"
        case crop
        case octaveOffset = "octave_offset"
        case includeVersion
    }
}

struct CropBounds: Codable, Sendable {
    let top: Double
    let bottom: Double
    let left: Double
    let right: Double
}

struct CachedKeysResponse: Codable, Sendable {
    let defaultKey: String
    let cachedKeys: [String]

    enum CodingKeys: String, CodingKey {
        case defaultKey = "default_key"
        case cachedKeys = "cached_keys"
    }
}

struct BulkCachedKeysResponse: Codable, Sendable {
    let cachedKeys: [String: [String]]
    let transposition: String
    let clef: String

    enum CodingKeys: String, CodingKey {
        case cachedKeys = "cached_keys"
        case transposition
        case clef
    }
}
