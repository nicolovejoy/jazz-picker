//
//  AddToSetlistSheet.swift
//  JazzPicker
//

import SwiftUI

struct AddToSetlistSheet: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(\.dismiss) private var dismiss

    let songTitle: String
    let concertKey: String

    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
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
                        .disabled(setlistStore.containsSong(songTitle, in: setlist))
                    }
                }

                Button {
                    newSetlistName = ""
                    showingCreateSheet = true
                } label: {
                    Label("New Setlist...", systemImage: "plus")
                }
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
                    if !newSetlistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        let setlist = setlistStore.createSetlist(name: newSetlistName.trimmingCharacters(in: .whitespaces))
                        addToSetlist(setlist)
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
        do {
            try setlistStore.addSong(to: setlist, songTitle: songTitle, concertKey: concertKey)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AddToSetlistSheet(songTitle: "Blue Bossa", concertKey: "c")
        .environment(SetlistStore())
}
