//
//  SetlistListView.swift
//  JazzPicker
//

import SwiftUI

struct SetlistListView: View {
    @Environment(SetlistStore.self) private var setlistStore
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showingCreateSheet = false
    @State private var newSetlistName = ""
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
            .task {
                // Load setlists on first appear
                if setlistStore.setlists.isEmpty {
                    await setlistStore.refresh()
                }
            }
            .alert("Create Setlist", isPresented: $showingCreateSheet) {
                TextField("Setlist name", text: $newSetlistName)
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let name = newSetlistName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        Task {
                            _ = await setlistStore.createSetlist(name: name)
                        }
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
        .refreshable {
            await setlistStore.refresh()
        }
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

#Preview("With Setlists") {
    SetlistListView()
        .environment(SetlistStore())
        .environment(NetworkMonitor())
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}

#Preview("Empty") {
    SetlistListView()
        .environment(SetlistStore())
        .environment(NetworkMonitor())
        .environment(CatalogStore())
        .environment(CachedKeysStore())
        .environment(PDFCacheService.shared)
}
