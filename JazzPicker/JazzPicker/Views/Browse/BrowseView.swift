//
//  BrowseView.swift
//  JazzPicker
//

import SwiftUI

struct BrowseView: View {
    @Environment(CatalogStore.self) private var catalogStore
    let instrument: Instrument

    @State private var searchText = ""
    @State private var selectedSongIndex: Int?

    var filteredSongs: [Song] {
        catalogStore.search(searchText)
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
                } else {
                    songList
                }
            }
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search songs")
            .refreshable {
                await catalogStore.refresh()
            }
            .task {
                if catalogStore.songs.isEmpty {
                    await catalogStore.load()
                }
            }
            .navigationDestination(item: $selectedSongIndex) { index in
                let songs = filteredSongs
                if index < songs.count {
                    let song = songs[index]
                    PDFViewerView(
                        song: song,
                        concertKey: song.defaultKey,
                        instrument: instrument,
                        navigationContext: .browse(songs: songs, currentIndex: index)
                    )
                }
            }
        }
    }

    private var songList: some View {
        List(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
            SongRow(song: song, instrument: instrument) {
                selectedSongIndex = index
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    BrowseView(instrument: .piano)
        .environment(CatalogStore())
}
