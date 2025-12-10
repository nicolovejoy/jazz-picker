//
//  BrowseView.swift
//  JazzPicker
//

import SwiftUI

struct BrowseView: View {
    @Environment(CatalogStore.self) private var catalogStore
    @Environment(CachedKeysStore.self) private var cachedKeysStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let instrument: Instrument

    @State private var searchText = ""
    @State private var selectedSong: SelectedSong?
    @State private var selectedComposer: String?

    private var useGrid: Bool {
        horizontalSizeClass == .regular
    }

    var filteredSongs: [Song] {
        catalogStore.search(searchText, composer: selectedComposer)
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
            .searchable(text: $searchText, prompt: "Search songs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("All Composers") {
                            selectedComposer = nil
                        }
                        Divider()
                        ForEach(catalogStore.composers, id: \.self) { composer in
                            Button(composer) {
                                selectedComposer = composer
                            }
                        }
                    } label: {
                        Label(
                            selectedComposer ?? "Composer",
                            systemImage: selectedComposer != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
                        )
                    }
                }
            }
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
        List(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
            SongRow(song: song, instrument: instrument) {
                selectedSong = SelectedSong(index: index, key: song.defaultKey)
            }
        }
        .listStyle(.plain)
    }

    private var songGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                ForEach(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
                    SongCard(song: song, instrument: instrument) { key in
                        // Set sticky key if non-standard
                        if key != song.defaultKey {
                            cachedKeysStore.setStickyKey(key, for: song)
                        }
                        selectedSong = SelectedSong(index: index, key: key)
                    }
                    .frame(height: 100)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    BrowseView(instrument: .piano)
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}
