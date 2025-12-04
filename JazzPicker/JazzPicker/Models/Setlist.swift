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

    init(id: UUID = UUID(), songTitle: String, concertKey: String, position: Int, isSetBreak: Bool = false) {
        self.id = id
        self.songTitle = songTitle
        self.concertKey = concertKey
        self.position = position
        self.isSetBreak = isSetBreak
    }

    static func song(_ title: String, key: String, position: Int) -> SetlistItem {
        SetlistItem(songTitle: title, concertKey: key, position: position, isSetBreak: false)
    }

    static func setBreak(position: Int) -> SetlistItem {
        SetlistItem(songTitle: "", concertKey: "", position: position, isSetBreak: true)
    }
}
