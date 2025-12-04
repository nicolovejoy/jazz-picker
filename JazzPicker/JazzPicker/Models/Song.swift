//
//  Song.swift
//  JazzPicker
//

import Foundation

struct Song: Codable, Identifiable, Hashable, Sendable {
    var id: String { title }

    let title: String
    let defaultKey: String
    let lowNoteMidi: Int?
    let highNoteMidi: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case defaultKey = "default_key"
        case lowNoteMidi = "low_note_midi"
        case highNoteMidi = "high_note_midi"
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

    enum CodingKeys: String, CodingKey {
        case url
        case cached
        case generationTimeMs = "generation_time_ms"
        case crop
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
