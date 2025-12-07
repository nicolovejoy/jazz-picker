//
//  Setlist.swift
//  JazzPicker
//

import Foundation

struct Setlist: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var items: [SetlistItem]
    var createdAt: Date
    var lastOpenedAt: Date
    var deletedAt: Date?

    init(id: UUID = UUID(), name: String, items: [SetlistItem] = [], createdAt: Date = Date(), lastOpenedAt: Date = Date(), deletedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.items = items
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.deletedAt = deletedAt
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var songCount: Int {
        items.filter { !$0.isSetBreak }.count
    }
}

struct SetlistItem: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var songTitle: String
    var concertKey: String
    var position: Int
    var isSetBreak: Bool
    var octaveOffset: Int

    init(id: UUID = UUID(), songTitle: String, concertKey: String, position: Int, isSetBreak: Bool = false, octaveOffset: Int = 0) {
        self.id = id
        self.songTitle = songTitle
        self.concertKey = concertKey
        self.position = position
        self.isSetBreak = isSetBreak
        self.octaveOffset = octaveOffset
    }

    // Custom decoder to handle missing octaveOffset from legacy responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        songTitle = try container.decode(String.self, forKey: .songTitle)
        concertKey = try container.decode(String.self, forKey: .concertKey)
        position = try container.decode(Int.self, forKey: .position)
        isSetBreak = try container.decode(Bool.self, forKey: .isSetBreak)
        octaveOffset = try container.decodeIfPresent(Int.self, forKey: .octaveOffset) ?? 0
    }

    static func song(_ title: String, key: String, position: Int) -> SetlistItem {
        SetlistItem(songTitle: title, concertKey: key, position: position, isSetBreak: false)
    }

    static func setBreak(position: Int) -> SetlistItem {
        SetlistItem(songTitle: "", concertKey: "", position: position, isSetBreak: true)
    }
}
