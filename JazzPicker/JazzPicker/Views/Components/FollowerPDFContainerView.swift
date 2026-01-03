//
//  FollowerPDFContainerView.swift
//  JazzPicker
//
//  Container view for Groove Sync followers that handles smooth chart-to-chart transitions.
//

import SwiftUI

struct FollowerPDFContainerView: View {
    @EnvironmentObject private var grooveSyncStore: GrooveSyncStore
    @EnvironmentObject private var catalogStore: CatalogStore
    @EnvironmentObject private var userProfileStore: UserProfileStore

    let instrument: Instrument
    let onStopFollowing: () -> Void

    @State private var currentSong: FollowingSong?
    @State private var isTransitioning = false
    @State private var lastProcessedSongKey: String?
    @State private var lastKnownPage: Int = 0  // Cache page to avoid flicker when Firestore updates

    /// Whether to show blank page (Page 2 mode, leader on last page or single-page chart)
    private var shouldShowBlankPage: Bool {
        guard grooveSyncStore.page2ModeEnabled,
              let session = grooveSyncStore.followingSession,
              let sharedSong = session.currentSong,
              let currentPage = sharedSong.currentPage,
              let pageCount = sharedSong.pageCount else {
            return false
        }
        // Show blank if single page or leader is on last page
        return pageCount == 1 || currentPage >= pageCount - 1
    }

    /// The page the follower should display
    /// In Page 2 mode: leader's page + 1
    /// Otherwise: leader's page (uses cached value if Firestore data temporarily unavailable)
    private var followerTargetPage: Int {
        guard let session = grooveSyncStore.followingSession,
              let sharedSong = session.currentSong,
              let currentPage = sharedSong.currentPage else {
            // Use cached page to avoid flicker during Firestore updates
            print("📄 followerTargetPage: no page info, using cached \(lastKnownPage)")
            return lastKnownPage
        }

        let target: Int
        if grooveSyncStore.page2ModeEnabled {
            target = currentPage + 1
            print("📄 followerTargetPage: Page 2 mode, leader on \(currentPage), returning \(target)")
        } else {
            target = currentPage
            print("📄 followerTargetPage: normal mode, returning \(target)")
        }
        return target
    }

    /// Update cached page when new page info arrives
    private func updateLastKnownPage() {
        if let session = grooveSyncStore.followingSession,
           let sharedSong = session.currentSong,
           let currentPage = sharedSong.currentPage {
            let target = grooveSyncStore.page2ModeEnabled ? currentPage + 1 : currentPage
            if target != lastKnownPage {
                print("📄 Updating lastKnownPage: \(lastKnownPage) → \(target)")
                lastKnownPage = target
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if shouldShowBlankPage {
                    // Page 2 mode: leader is on last page or single page chart
                    BlankPageView()
                } else if let song = currentSong {
                    // Normal view or Page 2 mode with pages remaining
                    PDFViewerView(
                        song: song.song,
                        concertKey: song.concertKey,
                        instrument: instrument,
                        octaveOffset: song.octaveOffset,
                        initialPage: followerTargetPage,
                        navigationContext: .single
                    )
                    .id(page2ViewId)  // Force new view on song or page change in Page 2 mode
                } else {
                    // Waiting for first song
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Waiting for leader to select a song...")
                            .foregroundStyle(.secondary)
                    }
                }

                // Loading indicator during transitions
                if isTransitioning {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            LoadingNextChartIndicator()
                                .padding()
                        }
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isTransitioning)
            .animation(.easeInOut(duration: 0.2), value: shouldShowBlankPage)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stop Following") {
                        Task {
                            await grooveSyncStore.stopFollowing()
                        }
                        onStopFollowing()
                    }
                }

                // Page 2 mode indicator
                if grooveSyncStore.page2ModeEnabled {
                    ToolbarItem(placement: .principal) {
                        Text("Page 2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear {
            updateLastKnownPage()
            updateFromSession()
        }
        .onChange(of: grooveSyncStore.followingSession) { _, _ in
            updateLastKnownPage()
            updateFromSession()
        }
    }

    /// View ID that changes when song changes (and when page changes in Page 2 mode)
    /// Uses cached lastKnownPage to avoid flicker when Firestore data temporarily unavailable
    private var page2ViewId: String {
        var id = currentSong?.id.uuidString ?? ""
        if grooveSyncStore.page2ModeEnabled {
            // Use cached page for stable ID
            id += "-page\(lastKnownPage)"
        }
        return id
    }

    private func updateFromSession() {
        guard grooveSyncStore.isFollowing,
              let session = grooveSyncStore.followingSession,
              let sharedSong = session.currentSong else {
            return
        }

        let newSongKey = "\(sharedSong.title)-\(sharedSong.concertKey)-\(sharedSong.octaveOffset ?? 0)"

        // Skip if same song
        guard newSongKey != lastProcessedSongKey else { return }

        // Look up song in catalog
        guard let song = catalogStore.songs.first(where: { $0.title == sharedSong.title }) else {
            return
        }

        // Show loading indicator if we're changing from an existing song
        if currentSong != nil {
            isTransitioning = true
        }

        lastProcessedSongKey = newSongKey
        currentSong = FollowingSong(
            song: song,
            concertKey: sharedSong.concertKey,
            octaveOffset: sharedSong.octaveOffset
        )

        // Hide loading indicator after a short delay (PDF will load quickly from cache usually)
        if isTransitioning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTransitioning = false
            }
        }
    }
}
