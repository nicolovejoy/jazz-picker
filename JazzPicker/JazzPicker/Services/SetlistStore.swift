//
//  SetlistStore.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation
import Observation

enum SetlistError: LocalizedError {
    case songAlreadyInSetlist(songTitle: String)
    case setlistNotFound
    case itemNotFound
    case notAuthenticated
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .songAlreadyInSetlist(let title):
            return "'\(title)' is already in this setlist"
        case .setlistNotFound:
            return "Setlist not found"
        case .itemNotFound:
            return "Item not found"
        case .notAuthenticated:
            return "You must be signed in"
        case .networkError(let message):
            return message
        }
    }
}

@Observable
class SetlistStore {
    private(set) var setlists: [Setlist] = []
    private(set) var isLoading: Bool = false
    private(set) var lastError: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private var currentOwnerId: String?

    @ObservationIgnored
    private let lastOpenedKey = "setlistLastOpened"

    /// Active setlists sorted by most recently opened
    var activeSetlists: [Setlist] {
        setlists.sorted { lastOpened($0.id) > lastOpened($1.id) }
    }

    /// The most recently opened setlist, if any
    var currentSetlist: Setlist? {
        activeSetlists.first
    }

    // MARK: - Listening

    func startListening(ownerId: String) {
        guard listener == nil else { return }

        isLoading = true
        lastError = nil
        currentOwnerId = ownerId

        listener = SetlistFirestoreService.subscribeToSetlists { [weak self] setlists in
            self?.setlists = setlists
            self?.isLoading = false
            print("📋 Received \(setlists.count) setlists from Firestore")
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        setlists = []
        currentOwnerId = nil
        isLoading = false
    }

    // MARK: - CRUD Operations (Optimistic UI)

    func createSetlist(name: String) async -> Setlist? {
        guard let ownerId = currentOwnerId else {
            lastError = SetlistError.notAuthenticated.localizedDescription
            return nil
        }

        lastError = nil

        // Optimistic: create local setlist immediately
        let tempId = UUID().uuidString
        let tempSetlist = Setlist(id: tempId, name: name, ownerId: ownerId)
        setlists.insert(tempSetlist, at: 0)

        do {
            let serverId = try await SetlistFirestoreService.createSetlist(name: name, ownerId: ownerId)
            // The listener will update with the real setlist, remove temp
            setlists.removeAll { $0.id == tempId }
            // Return a setlist with the server ID for immediate use
            return Setlist(id: serverId, name: name, ownerId: ownerId)
        } catch {
            // Rollback
            setlists.removeAll { $0.id == tempId }
            lastError = "Couldn't create setlist: \(error.localizedDescription)"
            print("❌ Failed to create setlist: \(error)")
            return nil
        }
    }

    func deleteSetlist(_ setlist: Setlist) async {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }

        // Optimistic: remove locally
        let backup = setlists[index]
        setlists.remove(at: index)

        do {
            try await SetlistFirestoreService.deleteSetlist(id: setlist.id)
            // Clear last opened data
            clearLastOpened(setlist.id)
        } catch {
            // Rollback
            setlists.insert(backup, at: min(index, setlists.count))
            lastError = "Couldn't delete setlist: \(error.localizedDescription)"
            print("❌ Failed to delete setlist: \(error)")
        }
    }

    func renameSetlist(_ setlist: Setlist, to name: String) async {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }

        // Optimistic update
        let oldName = setlists[index].name
        setlists[index].name = name

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, name: name)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].name = oldName
            }
            lastError = "Couldn't rename setlist: \(error.localizedDescription)"
            print("❌ Failed to rename setlist: \(error)")
        }
    }

    func markOpened(_ setlist: Setlist) {
        setLastOpened(setlist.id, date: Date())
    }

    // MARK: - Item Operations (Optimistic UI)

    func addSong(to setlist: Setlist, songTitle: String, concertKey: String, octaveOffset: Int = 0) async throws {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        // Check for duplicate
        let hasSong = setlists[index].items.contains { $0.songTitle == songTitle && !$0.isSetBreak }
        if hasSong {
            throw SetlistError.songAlreadyInSetlist(songTitle: songTitle)
        }

        // Optimistic update
        let position = setlists[index].items.count
        let item = SetlistItem(songTitle: songTitle, concertKey: concertKey, position: position, octaveOffset: octaveOffset)
        setlists[index].items.append(item)

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[index].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].items.removeAll { $0.id == item.id }
            }
            lastError = "Couldn't add song: \(error.localizedDescription)"
            throw SetlistError.networkError(error.localizedDescription)
        }
    }

    func addSetBreak(to setlist: Setlist) async throws {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        // Optimistic update
        let position = setlists[index].items.count
        let item = SetlistItem.setBreak(position: position)
        setlists[index].items.append(item)

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[index].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].items.removeAll { $0.id == item.id }
            }
            lastError = "Couldn't add set break: \(error.localizedDescription)"
            throw SetlistError.networkError(error.localizedDescription)
        }
    }

    func removeItem(from setlist: Setlist, item: SetlistItem) async throws {
        lastError = nil

        guard let setlistIndex = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        guard let itemIndex = setlists[setlistIndex].items.firstIndex(where: { $0.id == item.id }) else {
            throw SetlistError.itemNotFound
        }

        // Backup for rollback
        let backup = setlists[setlistIndex].items

        // Optimistic update
        setlists[setlistIndex].items.remove(at: itemIndex)
        reindexItems(setlistIndex: setlistIndex)

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[setlistIndex].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].items = backup
            }
            lastError = "Couldn't remove item: \(error.localizedDescription)"
            throw SetlistError.networkError(error.localizedDescription)
        }
    }

    func moveItem(in setlist: Setlist, from sourceIndex: Int, to destinationIndex: Int) async {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        guard sourceIndex != destinationIndex else { return }

        // Backup for rollback
        let backup = setlists[index].items

        // Optimistic update
        let item = setlists[index].items.remove(at: sourceIndex)
        let insertIndex = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        setlists[index].items.insert(item, at: insertIndex)
        reindexItems(setlistIndex: index)

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[index].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].items = backup
            }
            lastError = "Couldn't reorder items: \(error.localizedDescription)"
            print("❌ Failed to move item: \(error)")
        }
    }

    func updateItemOctaveOffset(in setlist: Setlist, itemID: String, octaveOffset: Int) async {
        lastError = nil

        guard let setlistIndex = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        guard let itemIndex = setlists[setlistIndex].items.firstIndex(where: { $0.id == itemID }) else { return }

        // Skip if no change
        guard setlists[setlistIndex].items[itemIndex].octaveOffset != octaveOffset else { return }

        // Backup for rollback
        let oldOffset = setlists[setlistIndex].items[itemIndex].octaveOffset

        // Optimistic update
        setlists[setlistIndex].items[itemIndex].octaveOffset = octaveOffset

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[setlistIndex].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }),
               let iIdx = setlists[idx].items.firstIndex(where: { $0.id == itemID }) {
                setlists[idx].items[iIdx].octaveOffset = oldOffset
            }
            lastError = "Couldn't save octave offset: \(error.localizedDescription)"
            print("❌ Failed to update octave offset: \(error)")
        }
    }

    func replaceItem(in setlist: Setlist, existingItemID: String, songTitle: String, concertKey: String, octaveOffset: Int) async throws {
        lastError = nil

        guard let setlistIndex = setlists.firstIndex(where: { $0.id == setlist.id }) else {
            throw SetlistError.setlistNotFound
        }

        guard let itemIndex = setlists[setlistIndex].items.firstIndex(where: { $0.id == existingItemID }) else {
            throw SetlistError.itemNotFound
        }

        // Backup for rollback
        let backup = setlists[setlistIndex].items[itemIndex]

        // Optimistic update
        setlists[setlistIndex].items[itemIndex].concertKey = concertKey
        setlists[setlistIndex].items[itemIndex].octaveOffset = octaveOffset

        do {
            try await SetlistFirestoreService.updateSetlist(id: setlist.id, items: setlists[setlistIndex].items)
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }),
               let iIdx = setlists[idx].items.firstIndex(where: { $0.id == existingItemID }) {
                setlists[idx].items[iIdx] = backup
            }
            lastError = "Couldn't update item: \(error.localizedDescription)"
            throw SetlistError.networkError(error.localizedDescription)
        }
    }

    func containsSong(_ songTitle: String, in setlist: Setlist) -> Bool {
        setlist.items.contains { $0.songTitle == songTitle && !$0.isSetBreak }
    }

    func findItem(_ songTitle: String, in setlist: Setlist) -> SetlistItem? {
        setlist.items.first { $0.songTitle == songTitle && !$0.isSetBreak }
    }

    // MARK: - Helpers

    private func reindexItems(setlistIndex: Int) {
        for i in setlists[setlistIndex].items.indices {
            setlists[setlistIndex].items[i].position = i
        }
    }

    /// Clear any displayed error
    func clearError() {
        lastError = nil
    }

    // MARK: - Last Opened (Local Storage)

    private func lastOpened(_ setlistId: String) -> Date {
        let dict = UserDefaults.standard.dictionary(forKey: lastOpenedKey) as? [String: Date] ?? [:]
        return dict[setlistId] ?? .distantPast
    }

    private func setLastOpened(_ setlistId: String, date: Date) {
        var dict = UserDefaults.standard.dictionary(forKey: lastOpenedKey) as? [String: Date] ?? [:]
        dict[setlistId] = date
        UserDefaults.standard.set(dict, forKey: lastOpenedKey)
    }

    private func clearLastOpened(_ setlistId: String) {
        var dict = UserDefaults.standard.dictionary(forKey: lastOpenedKey) as? [String: Date] ?? [:]
        dict.removeValue(forKey: setlistId)
        UserDefaults.standard.set(dict, forKey: lastOpenedKey)
    }
}
