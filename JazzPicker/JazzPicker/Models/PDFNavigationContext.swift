//
//  PDFNavigationContext.swift
//  JazzPicker
//

import Foundation

/// Defines the navigation context for PDF viewing, determining how swipe gestures
/// navigate between songs at page boundaries.
enum PDFNavigationContext {
    /// Browsing filtered song list - swipe navigates alphabetically through results
    case browse(songs: [Song], currentIndex: Int)

    /// Playing through a setlist - swipe navigates in setlist order
    /// Uses SetlistItem's concertKey which may differ from song's defaultKey
    case setlist(items: [SetlistItem], currentIndex: Int)

    /// Random spin mode - swipe triggers another random song
    case spin(randomSongProvider: () -> Song?)

    /// Single song view with no navigation (e.g., deep link)
    case single

    // MARK: - Navigation Helpers

    var canGoNext: Bool {
        switch self {
        case .browse(let songs, let index):
            return index < songs.count - 1
        case .setlist(let items, let index):
            return index < items.count - 1
        case .spin:
            return true // Always can spin again
        case .single:
            return false
        }
    }

    var canGoPrevious: Bool {
        switch self {
        case .browse(_, let index):
            return index > 0
        case .setlist(_, let index):
            return index > 0
        case .spin:
            return false // No "previous" in spin mode
        case .single:
            return false
        }
    }

    func nextSong() -> (song: Song, concertKey: String, newContext: PDFNavigationContext)? {
        switch self {
        case .browse(let songs, let index):
            guard index < songs.count - 1 else { return nil }
            let nextIndex = index + 1
            let song = songs[nextIndex]
            return (song, song.defaultKey, .browse(songs: songs, currentIndex: nextIndex))

        case .setlist(let items, let index):
            guard index < items.count - 1 else { return nil }
            let nextIndex = index + 1
            let item = items[nextIndex]
            // TODO: Need to look up Song from title when setlists are implemented
            // For now, create a minimal Song
            let song = Song(title: item.songTitle, defaultKey: item.concertKey, lowNoteMidi: nil, highNoteMidi: nil)
            return (song, item.concertKey, .setlist(items: items, currentIndex: nextIndex))

        case .spin(let provider):
            guard let song = provider() else { return nil }
            return (song, song.defaultKey, self) // Context stays the same for spin

        case .single:
            return nil
        }
    }

    func previousSong() -> (song: Song, concertKey: String, newContext: PDFNavigationContext)? {
        switch self {
        case .browse(let songs, let index):
            guard index > 0 else { return nil }
            let prevIndex = index - 1
            let song = songs[prevIndex]
            return (song, song.defaultKey, .browse(songs: songs, currentIndex: prevIndex))

        case .setlist(let items, let index):
            guard index > 0 else { return nil }
            let prevIndex = index - 1
            let item = items[prevIndex]
            let song = Song(title: item.songTitle, defaultKey: item.concertKey, lowNoteMidi: nil, highNoteMidi: nil)
            return (song, item.concertKey, .setlist(items: items, currentIndex: prevIndex))

        case .spin, .single:
            return nil
        }
    }
}

// MARK: - Setlist Types (placeholder until Phase 2)

struct SetlistItem: Codable, Identifiable {
    let id: UUID
    var songTitle: String
    var concertKey: String
    var position: Int
}
