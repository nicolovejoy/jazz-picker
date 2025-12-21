//
//  CatalogStore.swift
//  JazzPicker
//

import Combine
import Foundation

class CatalogStore: ObservableObject {
    @Published private(set) var songs: [Song] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let cacheURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("catalog.json")
    }()

    func load() async {
        isLoading = true
        error = nil

        // Try loading from cache first
        if let cached = loadFromCache() {
            songs = cached
        }

        // Then try network refresh
        do {
            let freshSongs = try await APIClient.shared.fetchCatalog()
            songs = freshSongs
            saveToCache(freshSongs)
        } catch {
            // Only set error if we have no cached data
            if songs.isEmpty {
                self.error = error
            }
        }

        isLoading = false
    }

    func refresh() async {
        isLoading = true
        error = nil

        do {
            let freshSongs = try await APIClient.shared.fetchCatalog()
            songs = freshSongs
            saveToCache(freshSongs)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func search(_ query: String) -> [Song] {
        guard !query.isEmpty else { return songs }

        let lowercased = query.lowercased()
        return songs.filter { song in
            song.title.lowercased().contains(lowercased) ||
            (song.composer?.lowercased().contains(lowercased) ?? false)
        }
    }

    /// Get all unique composers, sorted alphabetically
    var composers: [String] {
        let allComposers = songs.compactMap(\.composer)
        return Array(Set(allComposers)).sorted()
    }

    func randomSong() -> Song? {
        songs.randomElement()
    }

    // MARK: - Cache

    private func loadFromCache() -> [Song]? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            return try JSONDecoder().decode([Song].self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToCache(_ songs: [Song]) {
        do {
            let data = try JSONEncoder().encode(songs)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save catalog cache: \(error)")
        }
    }
}
