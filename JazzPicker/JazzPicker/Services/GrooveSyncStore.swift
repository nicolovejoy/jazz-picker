//
//  GrooveSyncStore.swift
//  JazzPicker
//

import Combine
import FirebaseFirestore
import Foundation

class GrooveSyncStore: ObservableObject {
    // MARK: - Published State

    /// Whether the current user is leading a session
    @Published private(set) var isLeading: Bool = false

    /// The group ID where we're currently leading
    @Published private(set) var leadingGroupId: String?

    /// Active sessions in user's groups (for "join" banners)
    @Published private(set) var activeSessions: [GrooveSyncSession] = []

    /// Last error message
    @Published private(set) var lastError: String?

    // MARK: - Private State

    private var sessionListeners: [ListenerRegistration] = []
    private var currentUserId: String?
    private var currentUserName: String?
    private var currentGroupIds: [String]?

    // MARK: - Computed Properties

    /// Get active session for a specific group (if any, and not led by current user)
    func activeSessionForGroup(_ groupId: String) -> GrooveSyncSession? {
        activeSessions.first { $0.groupId == groupId && $0.leaderId != currentUserId }
    }

    /// Check if there's an active session in any group that the user can join
    var hasJoinableSession: Bool {
        activeSessions.contains { $0.leaderId != currentUserId }
    }

    /// Get the first joinable session (for banner display)
    var firstJoinableSession: GrooveSyncSession? {
        activeSessions.first { $0.leaderId != currentUserId }
    }

    // MARK: - Lifecycle

    func startListening(userId: String, userName: String, groupIds: [String]?) {
        stopListening()

        currentUserId = userId
        currentUserName = userName
        currentGroupIds = groupIds

        guard let ids = groupIds, !ids.isEmpty else {
            activeSessions = []
            return
        }

        sessionListeners = GrooveSyncService.subscribeToSessions(groupIds: ids) { [weak self] sessions in
            self?.activeSessions = sessions
            // Check if we're still leading (session might have been ended externally)
            if let leadingId = self?.leadingGroupId {
                let stillLeading = sessions.contains {
                    $0.groupId == leadingId && $0.leaderId == self?.currentUserId
                }
                if !stillLeading {
                    self?.isLeading = false
                    self?.leadingGroupId = nil
                }
            }
        }
    }

    func stopListening() {
        sessionListeners.forEach { $0.remove() }
        sessionListeners = []
        activeSessions = []
        isLeading = false
        leadingGroupId = nil
        currentUserId = nil
        currentUserName = nil
        currentGroupIds = nil
    }

    // MARK: - Leader Actions

    /// Start leading a Groove Sync session
    func startLeading(groupId: String) async -> Bool {
        print("🎵 startLeading called for groupId: \(groupId)")
        print("🎵 currentUserId: \(currentUserId ?? "nil"), currentUserName: \(currentUserName ?? "nil")")

        guard let userId = currentUserId, let userName = currentUserName else {
            print("🎵 ❌ Not signed in - userId or userName is nil")
            lastError = "You must be signed in"
            return false
        }

        // Check if someone else is already leading this group
        if let existingSession = activeSessions.first(where: { $0.groupId == groupId }),
           existingSession.leaderId != userId {
            print("🎵 ❌ Someone else is already leading: \(existingSession.leaderName)")
            lastError = "\(existingSession.leaderName) is already sharing"
            return false
        }

        do {
            print("🎵 Calling GrooveSyncService.startSession...")
            try await GrooveSyncService.startSession(groupId: groupId, userId: userId, userName: userName)
            print("🎵 ✅ Session started successfully")
            await MainActor.run {
                isLeading = true
                leadingGroupId = groupId
                lastError = nil
            }
            return true
        } catch {
            print("🎵 ❌ Failed to start Groove Sync: \(error)")
            await MainActor.run {
                lastError = "Couldn't start sharing: \(error.localizedDescription)"
            }
            return false
        }
    }

    /// Stop leading the current session
    func stopLeading() async {
        guard let groupId = leadingGroupId else { return }

        do {
            try await GrooveSyncService.endSession(groupId: groupId)
        } catch {
            print("❌ Failed to end Groove Sync: \(error)")
            // Still clear local state even if remote fails
        }

        await MainActor.run {
            isLeading = false
            leadingGroupId = nil
        }
    }

    /// Sync the current song to followers
    func syncSong(title: String, concertKey: String, source: String = "standard") async {
        print("🎵 syncSong called - leadingGroupId: \(leadingGroupId ?? "nil"), isLeading: \(isLeading)")
        guard let groupId = leadingGroupId, isLeading else {
            print("🎵 ❌ Not leading or no groupId, cannot sync")
            return
        }

        let song = SharedSong(title: title, concertKey: concertKey, source: source)
        do {
            print("🎵 Calling GrooveSyncService.updateCurrentSong...")
            try await GrooveSyncService.updateCurrentSong(groupId: groupId, song: song)
            print("🎵 ✅ Song synced successfully")
        } catch {
            print("🎵 ❌ Failed to sync song: \(error)")
            lastError = "Couldn't sync song: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    func clearError() {
        lastError = nil
    }
}
