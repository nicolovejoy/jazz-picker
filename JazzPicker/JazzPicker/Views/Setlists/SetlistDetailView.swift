//
//  SetlistDetailView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistDetailView: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(BandStore.self) private var bandStore
    @Environment(CatalogStore.self) private var catalogStore
    @Environment(PDFCacheService.self) private var pdfCacheService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(UserProfileStore.self) private var userProfileStore

    let setlist: Setlist

    @State private var selectedItem: SetlistItem?
    @State private var showingOfflineToast = false

    private var instrument: Instrument {
        userProfileStore.profile?.instrument ?? .piano
    }

    private var currentSetlist: Setlist {
        setlistStore.setlists.first { $0.id == setlist.id } ?? setlist
    }

    private var bandName: String? {
        bandStore.bands.first { $0.id == currentSetlist.groupId }?.name
    }

    private var showBandName: Bool {
        bandStore.bands.count > 1
    }

    /// Download all uncached songs in background
    private func downloadUncachedSongs() async {
        let songItems = currentSetlist.items
            .filter { !$0.isSetBreak }
            .map { (songTitle: $0.songTitle, concertKey: $0.concertKey) }

        await pdfCacheService.downloadSetlistForOffline(
            items: songItems,
            transposition: instrument.transposition,
            clef: instrument.clef,
            instrumentLabel: instrument.label
        )
    }

    var body: some View {
        Group {
            if currentSetlist.items.isEmpty {
                ContentUnavailableView {
                    Label("No Songs", systemImage: "music.note")
                } description: {
                    Text("Add songs from the Browse tab")
                }
            } else {
                List {
                    ForEach(currentSetlist.items) { item in
                        if item.isSetBreak {
                            SetBreakRow()
                        } else {
                            SongItemRow(
                                item: item,
                                isCached: pdfCacheService.isCached(
                                    songTitle: item.songTitle,
                                    concertKey: item.concertKey,
                                    transposition: instrument.transposition,
                                    clef: instrument.clef
                                )
                            ) {
                                selectedItem = item
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if !networkMonitor.isConnected {
                            showingOfflineToast = true
                            return
                        }
                        for index in indexSet {
                            let item = currentSetlist.items[index]
                            Task {
                                try? await setlistStore.removeItem(from: currentSetlist, item: item)
                            }
                        }
                    }
                    .onMove { source, destination in
                        if !networkMonitor.isConnected {
                            showingOfflineToast = true
                            return
                        }
                        guard let sourceIndex = source.first else { return }
                        Task {
                            await setlistStore.moveItem(in: currentSetlist, from: sourceIndex, to: destination)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(currentSetlist.name)
        .toolbar {
            if showBandName, let bandName = bandName {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(currentSetlist.name)
                            .font(.headline)
                        Text(bandName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !currentSetlist.items.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                        .disabled(!networkMonitor.isConnected)
                }
            }
        }
        .onAppear {
            setlistStore.markOpened(currentSetlist)
        }
        .task {
            // Auto-download uncached songs for offline use
            await downloadUncachedSongs()
        }
        .navigationDestination(item: $selectedItem) { item in
            let items = currentSetlist.items.filter { !$0.isSetBreak }
            let index = items.firstIndex { $0.id == item.id } ?? 0
            let song = Song(title: item.songTitle, defaultKey: item.concertKey, composer: nil, lowNoteMidi: nil, highNoteMidi: nil)

            PDFViewerView(
                song: song,
                concertKey: item.concertKey,
                instrument: instrument,
                navigationContext: .setlist(setlistID: currentSetlist.id, items: items, currentIndex: index)
            )
        }
        .overlay(alignment: .bottom) {
            if showingOfflineToast {
                offlineToast
            }
        }
    }

    private var offlineToast: some View {
        Text("You must be online to modify setlists")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.red.opacity(0.9), in: Capsule())
            .padding(.bottom, 20)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingOfflineToast = false
                }
            }
    }
}

struct SongItemRow: View {
    let item: SetlistItem
    let isCached: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(item.songTitle)
                    .foregroundStyle(.primary)
                Spacer()

                // Subtle cache indicator
                if isCached {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.4))
                }

                Text(formatKey(item.concertKey))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formatKey(_ key: String) -> String {
        let isMinor = key.hasSuffix("m")
        let pitchPart = isMinor ? String(key.dropLast()) : key

        var result = pitchPart.prefix(1).uppercased()

        if pitchPart.count > 1 {
            let modifier = pitchPart.dropFirst()
            if modifier == "f" {
                result += "b"
            } else if modifier == "s" {
                result += "#"
            }
        }

        return isMinor ? result + " Minor" : result
    }
}

struct SetBreakRow: View {
    var body: some View {
        HStack {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            Text("Set Break")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .listRowBackground(Color.clear)
    }
}

#Preview {
    NavigationStack {
        SetlistDetailView(setlist: Setlist(name: "Friday Gig", ownerId: "preview-user", groupId: "preview-group"))
    }
    .environment(SetlistStore())
    .environment(BandStore())
    .environment(NetworkMonitor())
    .environment(CatalogStore())
    .environment(CachedKeysStore())
    .environment(PDFCacheService.shared)
    .environment(UserProfileStore())
}
