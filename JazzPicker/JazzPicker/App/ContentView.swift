//
//  ContentView.swift
//  JazzPicker
//
//  Created by Nicholas Lovejoy on 12/4/25.
//

import SwiftUI

/// Represents a song being followed via Groove Sync
struct FollowingSong: Identifiable {
    let id = UUID()
    let song: Song
    let concertKey: String
    let octaveOffset: Int?
}

struct ContentView: View {
    @EnvironmentObject private var catalogStore: CatalogStore
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @EnvironmentObject private var setlistStore: SetlistStore
    @EnvironmentObject private var grooveSyncStore: GrooveSyncStore
    @Environment(\.pendingJoinCode) private var pendingJoinCode
    @Environment(\.pendingSetlistId) private var pendingSetlistId
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var spinSong: Song?
    @State private var joinCodeToProcess: String?
    @State private var setlistToOpen: Setlist?

    // Groove Sync follower state
    @State private var showGrooveSyncModal = false
    @State private var dismissedSessionId: String?  // Track dismissed session to avoid re-showing
    @State private var isShowingFollowerView = false  // Persistent follower view

    var instrument: Instrument {
        userProfileStore.profile?.instrument ?? .piano
    }

    var body: some View {
        mainContent
            .withGrooveSyncFollower(
                grooveSyncStore: grooveSyncStore,
                instrument: instrument,
                showModal: $showGrooveSyncModal,
                dismissedSessionId: $dismissedSessionId,
                isShowingFollowerView: $isShowingFollowerView
            )
    }

    private var mainContent: some View {
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
        .onChange(of: pendingSetlistId.wrappedValue) { _, newValue in
            if let id = newValue {
                pendingSetlistId.wrappedValue = nil
                // Find setlist in store or load it
                if let existing = setlistStore.setlists.first(where: { $0.id == id }) {
                    setlistToOpen = existing
                } else {
                    // Load setlist by ID
                    Task {
                        if let setlist = await SetlistFirestoreService.getSetlist(id: id) {
                            await MainActor.run {
                                setlistToOpen = setlist
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $joinCodeToProcess) { code in
            NavigationStack {
                DeepLinkJoinView(code: code)
            }
        }
        .fullScreenCover(item: $setlistToOpen) { setlist in
            NavigationStack {
                SetlistDetailView(setlist: setlist)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                setlistToOpen = nil
                            }
                        }
                    }
            }
        }
    }
}

// MARK: - Groove Sync Follower ViewModifier

struct GrooveSyncFollowerModifier: ViewModifier {
    @ObservedObject var grooveSyncStore: GrooveSyncStore
    let instrument: Instrument
    @Binding var showModal: Bool
    @Binding var dismissedSessionId: String?
    @Binding var isShowingFollowerView: Bool

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isShowingFollowerView) {
                FollowerPDFContainerView(
                    instrument: instrument,
                    onStopFollowing: {
                        isShowingFollowerView = false
                    }
                )
            }
            .overlay { grooveSyncOverlay }
            .onChangeOfJoinableSession(grooveSyncStore: grooveSyncStore, dismissedSessionId: dismissedSessionId) {
                showModal = true
            }
            .onChange(of: grooveSyncStore.isFollowing) { _, isFollowing in
                // Show follower view when we start following
                if isFollowing && !isShowingFollowerView {
                    isShowingFollowerView = true
                }
                // Hide when we stop following
                if !isFollowing && isShowingFollowerView {
                    isShowingFollowerView = false
                }
            }
            .onChange(of: grooveSyncStore.activeSessions) { _, sessions in
                handleActiveSessionsChange(sessions)
            }
    }

    @ViewBuilder
    private var grooveSyncOverlay: some View {
        if showModal, let session = grooveSyncStore.firstJoinableSession {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showModal = false
                        dismissedSessionId = session.leaderId
                    }

                GrooveSyncModal(
                    session: session,
                    onJoin: {
                        showModal = false
                        Task {
                            await grooveSyncStore.startFollowing(session: session)
                        }
                    },
                    onDismiss: {
                        showModal = false
                        dismissedSessionId = session.leaderId
                    }
                )
            }
        }
    }

    private func handleActiveSessionsChange(_ sessions: [GrooveSyncSession]) {
        if let dismissedId = dismissedSessionId,
           !sessions.contains(where: { $0.leaderId == dismissedId }) {
            dismissedSessionId = nil
        }
    }
}

extension View {
    func withGrooveSyncFollower(
        grooveSyncStore: GrooveSyncStore,
        instrument: Instrument,
        showModal: Binding<Bool>,
        dismissedSessionId: Binding<String?>,
        isShowingFollowerView: Binding<Bool>
    ) -> some View {
        modifier(GrooveSyncFollowerModifier(
            grooveSyncStore: grooveSyncStore,
            instrument: instrument,
            showModal: showModal,
            dismissedSessionId: dismissedSessionId,
            isShowingFollowerView: isShowingFollowerView
        ))
    }

    func onChangeOfJoinableSession(
        grooveSyncStore: GrooveSyncStore,
        dismissedSessionId: String?,
        action: @escaping () -> Void
    ) -> some View {
        self.onChange(of: grooveSyncStore.hasJoinableSession) { _, hasSession in
            if hasSession,
               !grooveSyncStore.isLeading,
               !grooveSyncStore.isFollowing,
               grooveSyncStore.firstJoinableSession?.leaderId != dismissedSessionId {
                action()
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
        .environmentObject(GrooveSyncStore())
}
