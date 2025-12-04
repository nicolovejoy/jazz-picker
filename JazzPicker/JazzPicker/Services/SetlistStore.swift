//
//  SetlistStore.swift
//  JazzPicker
//

import Foundation
import Observation

enum SetlistError: LocalizedError {
    case songAlreadyInSetlist(songTitle: String)
    case setlistNotFound
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .songAlreadyInSetlist(let title):
            return "'\(title)' is already in this setlist"
        case .setlistNotFound:
            return "Setlist not found"
        case .itemNotFound:
            return "Item not found"
        }
    }
}

@Observable
class SetlistStore {
    private(set) var setlists: [Setlist] = []

    private let userDefaultsKey = "setlists"

    init() {
        load()
    }

    /// Active setlists sorted by most recently opened
    var activeSetlists: [Setlist] {
        setlists
            .filter { !$0.isDeleted }
            .sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }

    // MARK: - CRUD Operations

    func createSetlist(name: String) -> Setlist {
        let setlist = Setlist(name: name)
        setlists.append(setlist)
        save()
        return setlist
    }

    func deleteSetlist(_ setlist: Setlist) {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        setlists[index].deletedAt = Date()
        save()
    }

    func renameSetlist(_ setlist: Setlist, to name: String) {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        setlists[index].name = name
        save()
    }

    func markOpened(_ setlist: Setlist) {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        setlists[index].lastOpenedAt = Date()
        save()
    }

    // MARK: - Item Operations

    func addSong(to setlist: Setlist, songTitle: String, concertKey: String) throws {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        // Check for duplicate
        let hasSong = setlists[index].items.contains { $0.songTitle == songTitle && !$0.isSetBreak }
        if hasSong {
            throw SetlistError.songAlreadyInSetlist(songTitle: songTitle)
        }

        let position = setlists[index].items.count
        let item = SetlistItem.song(songTitle, key: concertKey, position: position)
        setlists[index].items.append(item)
        save()
    }

    func addSetBreak(to setlist: Setlist) throws {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        let position = setlists[index].items.count
        let item = SetlistItem.setBreak(position: position)
        setlists[index].items.append(item)
        save()
    }

    func removeItem(from setlist: Setlist, item: SetlistItem) throws {
        guard let setlistIndex = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        guard let itemIndex = setlists[setlistIndex].items.firstIndex(where: { $0.id == item.id }) else {
            throw SetlistError.itemNotFound
        }

        setlists[setlistIndex].items.remove(at: itemIndex)
        reindexItems(setlistIndex: setlistIndex)
        save()
    }

    func moveItem(in setlist: Setlist, from sourceIndex: Int, to destinationIndex: Int) {
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        guard sourceIndex != destinationIndex else { return }
        let item = setlists[index].items.remove(at: sourceIndex)
        let insertIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        setlists[index].items.insert(item, at: insertIndex)
        reindexItems(setlistIndex: index)
        save()
    }

    func containsSong(_ songTitle: String, in setlist: Setlist) -> Bool {
        setlist.items.contains { $0.songTitle == songTitle && !$0.isSetBreak }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        do {
            setlists = try JSONDecoder().decode([Setlist].self, from: data)
        } catch {
            print("Failed to load setlists: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(setlists)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save setlists: \(error)")
        }
    }

    private func reindexItems(setlistIndex: Int) {
        for i in setlists[setlistIndex].items.indices {
            setlists[setlistIndex].items[i].position = i
        }
    }
}
