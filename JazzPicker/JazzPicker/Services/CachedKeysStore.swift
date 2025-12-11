//
//  CachedKeysStore.swift
//  JazzPicker
//

import Foundation
import Observation

/// Manages cached keys from S3 and sticky key selections for the session
@Observable
class CachedKeysStore {
    /// Map of song slug -> array of cached concert keys
    private(set) var cachedKeys: [String: [String]] = [:]

    /// Map of song title -> sticky key (non-standard key user selected), persisted across sessions
    private(set) var stickyKeys: [String: String] = [:]

    private let stickyKeysKey = "stickyKeys"

    private(set) var isLoading = false
    private(set) var error: Error?

    private let cacheURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("cached_keys.json")
    }()

    init() {
        loadStickyKeys()
    }

    private func loadStickyKeys() {
        if let data = UserDefaults.standard.dictionary(forKey: stickyKeysKey) as? [String: String] {
            stickyKeys = data
        }
    }

    private func saveStickyKeys() {
        UserDefaults.standard.set(stickyKeys, forKey: stickyKeysKey)
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
        if let sticky = stickyKeys[song.title], let idx = otherKeys.firstIndex(of: sticky) {
            otherKeys.remove(at: idx)
            otherKeys.insert(sticky, at: 0)
        }

        return otherKeys
    }

    /// Check if a song has a sticky (non-standard) key set
    func getStickyKey(for song: Song) -> String? {
        stickyKeys[song.title]
    }

    /// Set a sticky key for a song (persisted across sessions)
    func setStickyKey(_ key: String, for song: Song) {
        // Don't set sticky if it's the default key
        if key == song.defaultKey {
            stickyKeys.removeValue(forKey: song.title)
        } else {
            stickyKeys[song.title] = key
        }
        saveStickyKeys()
    }

    /// Clear sticky key for a song
    func clearStickyKey(for song: Song) {
        stickyKeys.removeValue(forKey: song.title)
        saveStickyKeys()
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
