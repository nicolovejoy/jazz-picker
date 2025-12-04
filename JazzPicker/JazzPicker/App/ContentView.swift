//
//  ContentView.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(CatalogStore.self) private var catalogStore
    @Environment(CachedKeysStore.self) private var cachedKeysStore
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var spinSong: Song?
    @AppStorage("selectedInstrument") private var selectedInstrument: String = Instrument.piano.rawValue

    var instrument: Instrument {
        Instrument(rawValue: selectedInstrument) ?? .piano
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BrowseView(instrument: instrument)
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
                .tag(0)

            // Spin - acts as action button, not a real tab
            Color.clear
                .tabItem {
                    Label("Spin", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                }
                .tag(1)

            // Setlists - placeholder for Phase 2
            Text("Setlists")
                .tabItem {
                    Label("Setlists", systemImage: "music.note.list")
                }
                .tag(2)

            SettingsView(selectedInstrument: $selectedInstrument)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                // Spin tab selected - pick random song and show it
                previousTab = oldValue
                if let song = catalogStore.randomSong() {
                    spinSong = song
                }
                // Return to previous tab
                selectedTab = previousTab
            }
        }
        .fullScreenCover(item: $spinSong) { song in
            NavigationStack {
                PDFViewerView(
                    song: song,
                    concertKey: song.defaultKey,
                    instrument: instrument,
                    navigationContext: .spin(randomSongProvider: { catalogStore.randomSong() })
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            spinSong = nil
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(CatalogStore())
        .environment(CachedKeysStore())
}
