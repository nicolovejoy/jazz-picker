//
//  SetlistDetailView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistDetailView: View {
    @EnvironmentObject private var setlistStore: SetlistStore
    @EnvironmentObject private var bandStore: BandStore
    @EnvironmentObject private var catalogStore: CatalogStore
    @EnvironmentObject private var pdfCacheService: PDFCacheService
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @EnvironmentObject private var userProfileStore: UserProfileStore

    let setlist: Setlist

    @Environment(\.editMode) private var editMode

    @State private var selectedItem: SetlistItem?
    @State private var showingOfflineToast = false
    @State private var isAddingSetBreak = false
    @State private var showingCopiedToast = false
    @State private var editedName: String = ""

    private var instrument: Instrument {
        userProfileStore.profile?.instrument ?? .piano
    }

    private var currentSetlist: Setlist {
        setlistStore.setlists.first { $0.id == setlist.id } ?? setlist
    }

    private var bandName: String? {
        bandStore.bands.first { $0.id == currentSetlist.groupId }?.name
    }

    private var shareURL: URL {
        URL(string: "https://jazzpicker.pianohouseproject.org?setlist=\(currentSetlist.id)")!
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

    private func saveNameIfChanged() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != currentSetlist.name else { return }
        Task {
            await setlistStore.renameSetlist(currentSetlist, to: trimmed)
        }
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
                            SongItemRow(item: item) {
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
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(currentSetlist.name)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if editMode?.wrappedValue.isEditing == true {
                    TextField("Setlist Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit {
                            saveNameIfChanged()
                        }
                } else if showBandName, let bandName = bandName {
                    VStack(spacing: 0) {
                        Text(currentSetlist.name)
                            .font(.headline)
                        Text(bandName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                EditButton()
                    .disabled(!networkMonitor.isConnected)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    UIPasteboard.general.url = shareURL
                    showingCopiedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingCopiedToast = false
                    }
                } label: {
                    Label("Copy Link", systemImage: "link")
                }
            }
            if !currentSetlist.items.isEmpty {
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        if networkMonitor.isConnected {
                            isAddingSetBreak = true
                            Task {
                                try? await setlistStore.addSetBreak(to: currentSetlist)
                                isAddingSetBreak = false
                            }
                        } else {
                            showingOfflineToast = true
                        }
                    } label: {
                        Label("Add Set Break", systemImage: "minus")
                    }
                    .disabled(isAddingSetBreak || !networkMonitor.isConnected)
                }
            }
        }
        .onAppear {
            setlistStore.markOpened(currentSetlist)
        }
        .onChange(of: editMode?.wrappedValue) { oldValue, newValue in
            if newValue?.isEditing == true {
                editedName = currentSetlist.name
            } else if oldValue?.isEditing == true {
                saveNameIfChanged()
            }
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
            if showingCopiedToast {
                copiedToast
            }
        }
    }

    private var copiedToast: some View {
        Text("Link copied")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.green.opacity(0.9), in: Capsule())
            .padding(.bottom, 20)
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(item.songTitle)
                    .foregroundStyle(.primary)
                Spacer()
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
    .environmentObject(SetlistStore())
    .environmentObject(BandStore())
    .environmentObject(NetworkMonitor())
    .environmentObject(CatalogStore())
    .environmentObject(CachedKeysStore())
    .environmentObject(PDFCacheService.shared)
    .environmentObject(UserProfileStore())
}
