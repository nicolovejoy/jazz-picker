//
//  ContentView.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var catalogStore: CatalogStore
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @Environment(\.pendingJoinCode) private var pendingJoinCode
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var spinSong: Song?
    @State private var joinCodeToProcess: String?

    var instrument: Instrument {
        userProfileStore.profile?.instrument ?? .piano
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BrowseView(instrument: instrument)
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
                .tag(0)

            // Spin - acts as action button, not a real tab
            // Use BrowseView as placeholder so no flash when tapped
            BrowseView(instrument: instrument)
                .tabItem {
                    Label("Spin", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                }
                .tag(1)

            SetlistListView()
                .tabItem {
                    Label("Setlists", systemImage: "music.note.list")
                }
                .tag(2)

            SettingsView()
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
        .onChange(of: pendingJoinCode.wrappedValue) { _, newValue in
            if let code = newValue {
                joinCodeToProcess = code
                pendingJoinCode.wrappedValue = nil
            }
        }
        .sheet(item: $joinCodeToProcess) { code in
            NavigationStack {
                DeepLinkJoinView(code: code)
            }
        }
    }
}

// Make String conform to Identifiable for sheet presentation
extension String: @retroactive Identifiable {
    public var id: String { self }
}

#Preview {
    ContentView()
        .environmentObject(CatalogStore())
        .environmentObject(CachedKeysStore())
        .environmentObject(SetlistStore())
        .environmentObject(PDFCacheService.shared)
        .environmentObject(UserProfileStore())
}
