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
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .songAlreadyInSetlist(let title):
            return "'\(title)' is already in this setlist"
        case .setlistNotFound:
            return "Setlist not found"
        case .itemNotFound:
            return "Item not found"
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
    private let api = APIClient.shared

    @ObservationIgnored
    private let deviceID = DeviceID.getOrCreate()

    init() {
        // Wipe old UserDefaults data (one-time migration)
        UserDefaults.standard.removeObject(forKey: "setlists")
    }

    /// Active setlists sorted by most recently opened
    var activeSetlists: [Setlist] {
        setlists
            .filter { !$0.isDeleted }
            .sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }

    // MARK: - Refresh

    /// Fetch all setlists from the server
    func refresh() async {
        isLoading = true
        lastError = nil

        do {
            let fetched = try await api.fetchSetlists()
            setlists = fetched
            print("📋 Fetched \(fetched.count) setlists from server")
        } catch {
            lastError = "Couldn't load setlists: \(error.localizedDescription)"
            print("❌ Failed to fetch setlists: \(error)")
        }

        isLoading = false
    }

    // MARK: - CRUD Operations (Optimistic UI)

    func createSetlist(name: String) async -> Setlist? {
        lastError = nil

        // Optimistic: create local setlist immediately
        let tempSetlist = Setlist(name: name)
        setlists.append(tempSetlist)

        do {
            // API call
            let serverSetlist = try await api.createSetlist(name: name, deviceID: deviceID)

            // Replace temp with server response
            if let index = setlists.firstIndex(where: { $0.id == tempSetlist.id }) {
                setlists[index] = serverSetlist
            }
            return serverSetlist
        } catch {
            // Rollback
            setlists.removeAll { $0.id == tempSetlist.id }
            lastError = "Couldn't create setlist: \(error.localizedDescription)"
            print("❌ Failed to create setlist: \(error)")
            return nil
        }
    }

    func deleteSetlist(_ setlist: Setlist) async {
        lastError = nil

        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }

        // Optimistic: mark as deleted locally
        let backup = setlists[index]
        setlists[index].deletedAt = Date()

        do {
            try await api.deleteSetlist(id: setlist.id)
            // Success - remove from local array entirely
            setlists.removeAll { $0.id == setlist.id }
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx] = backup
            }
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
            _ = try await api.updateSetlist(setlists[index], deviceID: deviceID)
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
        // Local only - no API call needed, lastOpenedAt is derived from updated_at
        guard let index = setlists.firstIndex(where: { $0.id == setlist.id }) else { return }
        setlists[index].lastOpenedAt = Date()
    }

    // MARK: - Item Operations (Optimistic UI)

    func addSong(to setlist: Setlist, songTitle: String, concertKey: String) async throws {
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
        let item = SetlistItem.song(songTitle, key: concertKey, position: position)
        setlists[index].items.append(item)

        do {
            let updated = try await api.updateSetlist(setlists[index], deviceID: deviceID)
            // Replace with server response
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx] = updated
            }
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
            let updated = try await api.updateSetlist(setlists[index], deviceID: deviceID)
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx] = updated
            }
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
            let updated = try await api.updateSetlist(setlists[setlistIndex], deviceID: deviceID)
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx] = updated
            }
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
            let updated = try await api.updateSetlist(setlists[index], deviceID: deviceID)
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx] = updated
            }
        } catch {
            // Rollback
            if let idx = setlists.firstIndex(where: { $0.id == setlist.id }) {
                setlists[idx].items = backup
            }
            lastError = "Couldn't reorder items: \(error.localizedDescription)"
            print("❌ Failed to move item: \(error)")
        }
    }

    func containsSong(_ songTitle: String, in setlist: Setlist) -> Bool {
        setlist.items.contains { $0.songTitle == songTitle && !$0.isSetBreak }
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
}
