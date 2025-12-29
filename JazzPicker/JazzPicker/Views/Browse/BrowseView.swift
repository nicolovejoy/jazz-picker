//
//  BrowseView.swift
//  JazzPicker
//

import SwiftUI

/// Represents either a single song or a group of related parts
enum BrowseItem: Identifiable {
    case single(song: Song, index: Int)
    case group(scoreId: String, songs: [(song: Song, index: Int)])

    var id: String {
        switch self {
        case .single(let song, _): return song.id
        case .group(let scoreId, _): return "group:\(scoreId)"
        }
    }

    var displayTitle: String {
        switch self {
        case .single(let song, _): return song.title
        case .group(let scoreId, _): return scoreId
        }
    }
}

struct BrowseView: View {
    @EnvironmentObject private var catalogStore: CatalogStore
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let instrument: Instrument

    @State private var searchText = ""
    @State private var selectedSong: SelectedSong?
    @State private var expandedGroups: Set<String> = []

    private var useGrid: Bool {
        horizontalSizeClass == .regular
    }

    var filteredSongs: [Song] {
        catalogStore.search(searchText)
    }

    /// Group songs by scoreId for display, preserving flat indices for navigation
    var browseItems: [BrowseItem] {
        var items: [BrowseItem] = []
        var groups: [String: [(song: Song, index: Int)]] = [:]

        for (index, song) in filteredSongs.enumerated() {
            if let scoreId = song.scoreId {
                groups[scoreId, default: []].append((song, index))
            } else {
                items.append(.single(song: song, index: index))
            }
        }

        // Add groups (only if more than one part)
        for (scoreId, songs) in groups.sorted(by: { $0.key < $1.key }) {
            if songs.count > 1 {
                items.append(.group(scoreId: scoreId, songs: songs))
            } else if let first = songs.first {
                // Single-part "group" - show as regular song
                items.append(.single(song: first.song, index: first.index))
            }
        }

        // Sort by display title
        return items.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            Group {
                if catalogStore.isLoading && catalogStore.songs.isEmpty {
                    ProgressView("Loading songs...")
                } else if let error = catalogStore.error, catalogStore.songs.isEmpty {
                    ContentUnavailableView(
                        "Unable to Load Songs",
                        systemImage: "wifi.slash",
                        description: Text(error.localizedDescription)
                    )
                } else if useGrid {
                    songGrid
                } else {
                    songList
                }
            }
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search songs or composers")
            .refreshable {
                await catalogStore.refresh()
                await cachedKeysStore.refresh(for: instrument)
            }
            .task {
                if catalogStore.songs.isEmpty {
                    await catalogStore.load()
                }
                await cachedKeysStore.load(for: instrument)
            }
            .onChange(of: instrument.id) {
                // Reload cached keys when instrument changes
                Task {
                    await cachedKeysStore.load(for: instrument)
                }
            }
            .navigationDestination(item: $selectedSong) { selection in
                let songs = filteredSongs
                if selection.index < songs.count {
                    let song = songs[selection.index]
                    PDFViewerView(
                        song: song,
                        concertKey: selection.key,
                        instrument: instrument,
                        navigationContext: .browse(songs: songs, currentIndex: selection.index)
                    )
                }
            }
        }
    }

    /// Represents a song selection with index and chosen key
    struct SelectedSong: Hashable {
        let index: Int
        let key: String
    }

    private var songList: some View {
        List(browseItems) { item in
            switch item {
            case .single(let song, let index):
                SongRow(song: song, instrument: instrument) {
                    let key = cachedKeysStore.getStickyKey(for: song) ?? song.defaultKey
                    selectedSong = SelectedSong(index: index, key: key)
                }

            case .group(let scoreId, let songs):
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedGroups.contains(scoreId) },
                        set: { expanded in
                            if expanded {
                                expandedGroups.insert(scoreId)
                            } else {
                                expandedGroups.remove(scoreId)
                            }
                        }
                    )
                ) {
                    ForEach(songs, id: \.song.id) { item in
                        SongRow(song: item.song, instrument: instrument) {
                            let key = cachedKeysStore.getStickyKey(for: item.song) ?? item.song.defaultKey
                            selectedSong = SelectedSong(index: item.index, key: key)
                        }
                    }
                } label: {
                    HStack {
                        Text(scoreId)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(songs.count) parts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 16)], spacing: 16) {
                ForEach(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
                    SongCard(song: song, instrument: instrument) { key in
                        // Set sticky key if non-standard
                        if key != song.defaultKey {
                            cachedKeysStore.setStickyKey(key, for: song)
                        }
                        selectedSong = SelectedSong(index: index, key: key)
                    }
                    .frame(height: 140)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    BrowseView(instrument: .piano)
        .environmentObject(CatalogStore())
        .environmentObject(CachedKeysStore())
        .environmentObject(PDFCacheService.shared)
}
