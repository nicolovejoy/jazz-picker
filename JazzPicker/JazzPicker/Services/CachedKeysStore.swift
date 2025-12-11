//
//  CachedKeysStore.swift
//  JazzPicker
//

import FirebaseAuth
import Foundation
import Observation

/// Manages cached keys from S3 and delegates sticky key operations to UserProfileStore
@Observable
class CachedKeysStore {
    /// Map of song slug -> array of cached concert keys
    private(set) var cachedKeys: [String: [String]] = [:]

    private(set) var isLoading = false
    private(set) var error: Error?

    // Delegate sticky keys to UserProfileStore
    private weak var userProfileStore: UserProfileStore?
    private weak var authStore: AuthStore?

    private let cacheURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("cached_keys.json")
    }()

    /// Configure with stores for sticky key delegation
    func configure(userProfileStore: UserProfileStore, authStore: AuthStore) {
        self.userProfileStore = userProfileStore
        self.authStore = authStore
    }

    /// Load cached keys for the given instrument
    func load(for instrument: Instrument) async {
        isLoading = true
        error = nil

        // Load from local cache first
        if let cached = loadFromCache() {
            cachedKeys = cached
        }

        // Then fetch from network
        do {
            let response = try await APIClient.shared.fetchAllCachedKeys(
                transposition: instrument.transposition,
                clef: instrument.clef
            )
            cachedKeys = response.cachedKeys
            saveToCache(response.cachedKeys)
        } catch {
            // Only set error if we have no cached data
            if cachedKeys.isEmpty {
                self.error = error
            }
            print("Failed to fetch cached keys: \(error)")
        }

        isLoading = false
    }

    /// Refresh cached keys from network
    func refresh(for instrument: Instrument) async {
        isLoading = true
        error = nil

        do {
            let response = try await APIClient.shared.fetchAllCachedKeys(
                transposition: instrument.transposition,
                clef: instrument.clef
            )
            cachedKeys = response.cachedKeys
            saveToCache(response.cachedKeys)
        } catch {
            self.error = error
            print("Failed to refresh cached keys: \(error)")
        }

        isLoading = false
    }

    /// Get cached keys for a song, ordered by: sticky key first (if exists), then others
    func getCachedKeys(for song: Song) -> [String] {
        let slug = slugify(song.title)
        guard let keys = cachedKeys[slug] else { return [] }

        // Filter out the default key (it's shown separately)
        var otherKeys = keys.filter { $0 != song.defaultKey }

        // If there's a sticky key for this song, move it to front
        if let sticky = getStickyKey(for: song), let idx = otherKeys.firstIndex(of: sticky) {
            otherKeys.remove(at: idx)
            otherKeys.insert(sticky, at: 0)
        }

        return otherKeys
    }

    /// Check if a song has a sticky (non-standard) key set
    func getStickyKey(for song: Song) -> String? {
        userProfileStore?.getPreferredKey(for: song.title)
    }

    /// Set a sticky key for a song (synced to Firestore)
    func setStickyKey(_ key: String, for song: Song) {
        guard let uid = authStore?.user?.uid else { return }
        Task {
            await userProfileStore?.setPreferredKey(key, for: song.title, defaultKey: song.defaultKey, uid: uid)
        }
    }

    /// Clear sticky key for a song
    func clearStickyKey(for song: Song) {
        guard let uid = authStore?.user?.uid else { return }
        Task {
            await userProfileStore?.clearPreferredKey(for: song.title, uid: uid)
        }
    }

    /// Convert song title to slug (matches backend slugify function)
    private func slugify(_ text: String) -> String {
        var result = text.lowercased()
        // Remove non-alphanumeric except spaces and hyphens
        result = result.filter { $0.isLetter || $0.isNumber || $0 == " " || $0 == "-" }
        // Replace spaces and multiple hyphens with single hyphen
        result = result.replacingOccurrences(of: " ", with: "-")
        result = result.replacingOccurrences(of: "--", with: "-")
        // Trim hyphens from ends
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return result
    }

    // MARK: - Cache

    private func loadFromCache() -> [String: [String]]? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            return try JSONDecoder().decode([String: [String]].self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToCache(_ keys: [String: [String]]) {
        do {
            let data = try JSONEncoder().encode(keys)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save cached keys: \(error)")
        }
    }
}
