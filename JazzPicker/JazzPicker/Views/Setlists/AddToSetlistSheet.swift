//
//  AddToSetlistSheet.swift
//  JazzPicker
//

import SwiftUI

struct AddToSetlistSheet: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.dismiss) private var dismiss

    let songTitle: String
    let concertKey: String

    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
    @State private var errorMessage: String?
    @State private var isAdding = false

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
                            addToSetlist(setlist)
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
                        .disabled(setlistStore.containsSong(songTitle, in: setlist) || !networkMonitor.isConnected || isAdding)
                        .opacity(networkMonitor.isConnected ? 1 : 0.5)
                    }
                }

                Button {
                    newSetlistName = ""
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
            .alert("Create Setlist", isPresented: $showingCreateSheet) {
                TextField("Setlist name", text: $newSetlistName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newSetlistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        Task {
                            isAdding = true
                            if let setlist = await setlistStore.createSetlist(name: name) {
                                await addToSetlistAsync(setlist)
                            }
                            isAdding = false
                        }
                    }
                }
            } message: {
                Text("Enter a name for your new setlist")
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
        }
        .presentationDetents([.medium])
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
            try await setlistStore.addSong(to: setlist, songTitle: songTitle, concertKey: concertKey)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddToSetlistSheet(songTitle: "Blue Bossa", concertKey: "c")
        .environment(SetlistStore())
        .environment(NetworkMonitor())
}
