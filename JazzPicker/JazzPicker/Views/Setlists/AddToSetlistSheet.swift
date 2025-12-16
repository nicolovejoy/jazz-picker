//
//  AddToSetlistSheet.swift
//  JazzPicker
//

import SwiftUI

struct AddToSetlistSheet: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(BandStore.self) private var bandStore
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.dismiss) private var dismiss

    let songTitle: String
    let concertKey: String
    let octaveOffset: Int

    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
    @State private var selectedGroupId: String?
    @State private var errorMessage: String?
    @State private var isAdding = false
    @State private var conflictSetlist: Setlist?
    @State private var existingItem: SetlistItem?

    private var defaultGroupId: String? {
        userProfileStore.profile?.lastUsedGroupId ?? bandStore.bands.first?.id
    }

    var body: some View {
        NavigationStack {
            List {
                if !networkMonitor.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundStyle(.red)
                        Text("You must be online to modify setlists")
                            .foregroundStyle(.secondary)
                    }
                }

                if setlistStore.activeSetlists.isEmpty {
                    Text("No setlists yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(setlistStore.activeSetlists) { setlist in
                        Button {
                            handleSetlistTap(setlist)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(setlist.name)
                                        .foregroundStyle(.primary)
                                    Text("\(setlist.songCount) songs")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if setlistStore.containsSong(songTitle, in: setlist) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .disabled(!networkMonitor.isConnected || isAdding)
                        .opacity(networkMonitor.isConnected ? 1 : 0.5)
                    }
                }

                Button {
                    newSetlistName = ""
                    selectedGroupId = nil
                    showingCreateSheet = true
                } label: {
                    Label("New Setlist...", systemImage: "plus")
                }
                .disabled(!networkMonitor.isConnected || isAdding)
                .opacity(networkMonitor.isConnected ? 1 : 0.5)
            }
            .navigationTitle("Add to Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSetlistSheet(
                    name: $newSetlistName,
                    selectedGroupId: $selectedGroupId,
                    bands: bandStore.bands,
                    defaultGroupId: defaultGroupId
                ) {
                    let name = newSetlistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty, let groupId = selectedGroupId {
                        Task {
                            isAdding = true
                            if let setlist = await setlistStore.createSetlist(name: name, groupId: groupId) {
                                await addToSetlistAsync(setlist)
                            }
                            isAdding = false
                        }
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .confirmationDialog(
                "\"\(songTitle)\" already in setlist",
                isPresented: .init(
                    get: { conflictSetlist != nil },
                    set: { if !$0 { conflictSetlist = nil; existingItem = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Replace") {
                    if let setlist = conflictSetlist, let item = existingItem {
                        replaceItem(in: setlist, oldItem: item)
                    }
                }
                Button("Keep Existing", role: .cancel) {
                    conflictSetlist = nil
                    existingItem = nil
                }
            } message: {
                if let item = existingItem {
                    Text("Existing: \(item.concertKey.uppercased()) (\(formatOctave(item.octaveOffset)))\nNew: \(concertKey.uppercased()) (\(formatOctave(octaveOffset)))")
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func handleSetlistTap(_ setlist: Setlist) {
        if let existing = setlistStore.findItem(songTitle, in: setlist) {
            // Song exists - check if same key/octave
            if existing.concertKey == concertKey && existing.octaveOffset == octaveOffset {
                // Same values, nothing to change
                dismiss()
            } else {
                // Different values, show conflict dialog
                existingItem = existing
                conflictSetlist = setlist
            }
        } else {
            // Song not in setlist, add directly
            addToSetlist(setlist)
        }
    }

    private func addToSetlist(_ setlist: Setlist) {
        Task {
            isAdding = true
            await addToSetlistAsync(setlist)
            isAdding = false
        }
    }

    private func addToSetlistAsync(_ setlist: Setlist) async {
        do {
            try await setlistStore.addSong(to: setlist, songTitle: songTitle, concertKey: concertKey, octaveOffset: octaveOffset)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func replaceItem(in setlist: Setlist, oldItem: SetlistItem) {
        Task {
            isAdding = true
            do {
                try await setlistStore.removeItem(from: setlist, item: oldItem)
                try await setlistStore.addSong(to: setlist, songTitle: songTitle, concertKey: concertKey, octaveOffset: octaveOffset)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isAdding = false
        }
    }

    private func formatOctave(_ offset: Int) -> String {
        if offset == 0 { return "0" }
        return offset > 0 ? "+\(offset)" : "\(offset)"
    }
}

#Preview {
    AddToSetlistSheet(songTitle: "Blue Bossa", concertKey: "c", octaveOffset: 0)
        .environment(SetlistStore())
        .environment(BandStore())
        .environment(UserProfileStore())
        .environment(NetworkMonitor())
}
