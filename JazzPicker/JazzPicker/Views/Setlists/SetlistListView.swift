//
//  SetlistListView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistListView: View {
    @Environment(SetlistStore.self) private var setlistStore
    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
    @State private var setlistToDelete: Setlist?

    var body: some View {
        NavigationStack {
            Group {
                if setlistStore.activeSetlists.isEmpty {
                    emptyState
                } else {
                    setlistList
                }
            }
            .navigationTitle("Setlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newSetlistName = ""
                        showingCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Create Setlist", isPresented: $showingCreateSheet) {
                TextField("Setlist name", text: $newSetlistName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    if !newSetlistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = setlistStore.createSetlist(name: newSetlistName.trimmingCharacters(in: .whitespaces))
                    }
                }
            } message: {
                Text("Enter a name for your new setlist")
            }
            .alert("Delete Setlist?", isPresented: .init(
                get: { setlistToDelete != nil },
                set: { if !$0 { setlistToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) {
                    setlistToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let setlist = setlistToDelete {
                        setlistStore.deleteSetlist(setlist)
                    }
                    setlistToDelete = nil
                }
            } message: {
                if let setlist = setlistToDelete {
                    Text("Are you sure you want to delete \"\(setlist.name)\"?")
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Setlists", systemImage: "music.note.list")
        } description: {
            Text("Create a setlist to organize songs for your gig")
        } actions: {
            Button("Create Setlist") {
                newSetlistName = ""
                showingCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var setlistList: some View {
        List {
            ForEach(setlistStore.activeSetlists) { setlist in
                NavigationLink(value: setlist) {
                    SetlistCard(setlist: setlist)
                }
            }
            .onDelete { indexSet in
                if let index = indexSet.first {
                    setlistToDelete = setlistStore.activeSetlists[index]
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Setlist.self) { setlist in
            SetlistDetailView(setlist: setlist)
        }
    }
}

struct SetlistCard: View {
    let setlist: Setlist

    private var songPreview: String {
        let songTitles = setlist.items
            .filter { !$0.isSetBreak }
            .prefix(4)
            .map { $0.songTitle }

        if songTitles.isEmpty {
            return "No songs yet"
        }

        let preview = songTitles.joined(separator: ", ")
        if setlist.songCount > 4 {
            return preview + " ..."
        }
        return preview
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(setlist.name)
                .font(.headline)

            Text(songPreview)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview("With Setlists") {
    let store = SetlistStore()
    let setlist = store.createSetlist(name: "Friday Gig")
    try? store.addSong(to: setlist, songTitle: "Blue Bossa", concertKey: "c")
    try? store.addSong(to: setlist, songTitle: "Autumn Leaves", concertKey: "g")
    try? store.addSong(to: setlist, songTitle: "All The Things You Are", concertKey: "af")

    return SetlistListView()
        .environment(store)
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}

#Preview("Empty") {
    SetlistListView()
        .environment(SetlistStore())
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}
