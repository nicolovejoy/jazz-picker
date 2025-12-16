//
//  Setlist.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation

struct Setlist: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var ownerId: String
    var groupId: String
    var items: [SetlistItem]
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String, ownerId: String, groupId: String, items: [SetlistItem] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.groupId = groupId
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var songCount: Int {
        items.filter { !$0.isSetBreak }.count
    }

    // MARK: - Firestore Conversion

    init?(id: String, from data: [String: Any]) {
        guard let name = data["name"] as? String,
              let ownerId = data["ownerId"] as? String,
              let groupId = data["groupId"] as? String else {
            return nil
        }

        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.groupId = groupId
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

        if let itemsData = data["items"] as? [[String: Any]] {
            self.items = itemsData.compactMap { SetlistItem(from: $0) }
        } else {
            self.items = []
        }
    }

    func toFirestoreData() -> [String: Any] {
        [
            "name": name,
            "ownerId": ownerId,
            "groupId": groupId,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date()),
            "items": items.map { $0.toFirestoreData() }
        ]
    }
}

struct SetlistItem: Identifiable, Hashable, Sendable {
    let id: String
    var songTitle: String
    var concertKey: String
    var position: Int
    var isSetBreak: Bool
    var octaveOffset: Int
    var notes: String?

    init(id: String = UUID().uuidString, songTitle: String, concertKey: String, position: Int, isSetBreak: Bool = false, octaveOffset: Int = 0, notes: String? = nil) {
        self.id = id
        self.songTitle = songTitle
        self.concertKey = concertKey
        self.position = position
        self.isSetBreak = isSetBreak
        self.octaveOffset = octaveOffset
        self.notes = notes
    }

    // MARK: - Firestore Conversion

    init?(from data: [String: Any]) {
        guard let id = data["id"] as? String,
              let songTitle = data["songTitle"] as? String,
              let position = data["position"] as? Int else {
            return nil
        }

        self.id = id
        self.songTitle = songTitle
        self.concertKey = data["concertKey"] as? String ?? ""
        self.position = position
        self.isSetBreak = data["isSetBreak"] as? Bool ?? false
        self.octaveOffset = data["octaveOffset"] as? Int ?? 0
        self.notes = data["notes"] as? String
    }

    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "songTitle": songTitle,
            "concertKey": concertKey,
            "position": position,
            "isSetBreak": isSetBreak,
            "octaveOffset": octaveOffset
        ]
        if let notes = notes {
            data["notes"] = notes
        }
        return data
    }

    static func song(_ title: String, key: String, position: Int) -> SetlistItem {
        SetlistItem(songTitle: title, concertKey: key, position: position, isSetBreak: false)
    }

    static func setBreak(position: Int) -> SetlistItem {
        SetlistItem(songTitle: "", concertKey: "", position: position, isSetBreak: true)
    }
}
