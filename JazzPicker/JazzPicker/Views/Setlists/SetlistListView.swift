//
//  SetlistListView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistListView: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(BandStore.self) private var bandStore
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
    @State private var selectedGroupId: String?
    @State private var setlistToDelete: Setlist?
    @State private var showingOfflineToast = false
    @State private var showingErrorToast = false

    var body: some View {
        NavigationStack {
            Group {
                if setlistStore.activeSetlists.isEmpty && !setlistStore.isLoading {
                    emptyState
                } else {
                    setlistList
                }
            }
            .navigationTitle("Setlists")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if networkMonitor.isConnected {
                            newSetlistName = ""
                            showingCreateSheet = true
                        } else {
                            showingOfflineToast = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .opacity(networkMonitor.isConnected ? 1 : 0.5)
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateSetlistSheet(
                    name: $newSetlistName,
                    selectedGroupId: $selectedGroupId,
                    bands: bandStore.bands,
                    defaultGroupId: userProfileStore.profile?.lastUsedGroupId ?? bandStore.bands.first?.id
                ) {
                    let name = newSetlistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        Task {
                            _ = await setlistStore.createSetlist(name: name, groupId: selectedGroupId)
                        }
                    }
                }
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
                        Task {
                            await setlistStore.deleteSetlist(setlist)
                        }
                    }
                    setlistToDelete = nil
                }
            } message: {
                if let setlist = setlistToDelete {
                    Text("Are you sure you want to delete \"\(setlist.name)\"?")
                }
            }
            .overlay(alignment: .bottom) {
                if showingOfflineToast {
                    offlineToast
                }
                if showingErrorToast, let error = setlistStore.lastError {
                    errorToast(error)
                }
            }
            .onChange(of: setlistStore.lastError) { _, newValue in
                if newValue != nil {
                    showingErrorToast = true
                    // Auto-dismiss after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        showingErrorToast = false
                        setlistStore.clearError()
                    }
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
                if networkMonitor.isConnected {
                    newSetlistName = ""
                    showingCreateSheet = true
                } else {
                    showingOfflineToast = true
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!networkMonitor.isConnected)
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
                if !networkMonitor.isConnected {
                    showingOfflineToast = true
                    return
                }
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

    private func errorToast(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.orange.opacity(0.9), in: Capsule())
            .padding(.bottom, 20)
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

struct CreateSetlistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var selectedGroupId: String?
    let bands: [Band]
    let defaultGroupId: String?
    let onCreate: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Setlist name", text: $name)
                } footer: {
                    Text("e.g., Friday Night Set")
                }

                if bands.count >= 2 {
                    Section {
                        Picker("Band", selection: $selectedGroupId) {
                            ForEach(bands) { band in
                                Text(band.name).tag(band.id as String?)
                            }
                        }
                    } footer: {
                        Text("Which band will use this setlist?")
                    }
                }
            }
            .navigationTitle("Create Setlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                // Set default band if not already set
                if selectedGroupId == nil {
                    selectedGroupId = defaultGroupId ?? bands.first?.id
                }
            }
        }
    }
}

#Preview("With Setlists") {
    SetlistListView()
        .environment(SetlistStore())
        .environment(BandStore())
        .environment(UserProfileStore())
        .environment(NetworkMonitor())
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}

#Preview("Empty") {
    SetlistListView()
        .environment(SetlistStore())
        .environment(BandStore())
        .environment(UserProfileStore())
        .environment(NetworkMonitor())
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}
