//
//  SetlistDetailView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistDetailView: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(CatalogStore.self) private var catalogStore
    @Environment(PDFCacheService.self) private var pdfCacheService
    @AppStorage("selectedInstrument") private var selectedInstrument: String = Instrument.piano.rawValue

    let setlist: Setlist

    @State private var selectedItem: SetlistItem?

    private var instrument: Instrument {
        Instrument(rawValue: selectedInstrument) ?? .piano
    }

    private var currentSetlist: Setlist {
        setlistStore.setlists.first { $0.id == setlist.id } ?? setlist
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
                        for index in indexSet {
                            let item = currentSetlist.items[index]
                            try? setlistStore.removeItem(from: currentSetlist, item: item)
                        }
                    }
                    .onMove { source, destination in
                        guard let sourceIndex = source.first else { return }
                        setlistStore.moveItem(in: currentSetlist, from: sourceIndex, to: destination)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(currentSetlist.name)
        .toolbar {
            if !currentSetlist.items.isEmpty {
                EditButton()
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
            let song = Song(title: item.songTitle, defaultKey: item.concertKey, lowNoteMidi: nil, highNoteMidi: nil)

            PDFViewerView(
                song: song,
                concertKey: item.concertKey,
                instrument: instrument,
                navigationContext: .setlist(items: items, currentIndex: index)
            )
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

        return isMinor ? result + "m" : result
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
    let store = SetlistStore()
    let setlist = store.createSetlist(name: "Friday Gig")
    try? store.addSong(to: setlist, songTitle: "Blue Bossa", concertKey: "c")
    try? store.addSong(to: setlist, songTitle: "Autumn Leaves", concertKey: "g")

    return NavigationStack {
        SetlistDetailView(setlist: setlist)
    }
    .environment(store)
    .environment(CatalogStore())
    .environment(CachedKeysStore())
    .environment(PDFCacheService.shared)
}
