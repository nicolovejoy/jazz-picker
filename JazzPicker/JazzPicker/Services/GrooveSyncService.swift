//
//  GrooveSyncService.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation

/// Represents the current song being shared in a Groove Sync session
struct SharedSong: Sendable {
    let title: String
    let concertKey: String
    let source: String  // "standard" or "custom"

    init(title: String, concertKey: String, source: String = "standard") {
        self.title = title
        self.concertKey = concertKey
        self.source = source
    }

    init?(from data: [String: Any]) {
        guard let title = data["title"] as? String,
              let concertKey = data["concertKey"] as? String else {
            return nil
        }
        self.title = title
        self.concertKey = concertKey
        self.source = data["source"] as? String ?? "standard"
    }

    func toFirestoreData() -> [String: Any] {
        [
            "title": title,
            "concertKey": concertKey,
            "source": source
        ]
    }
}

/// Represents an active Groove Sync session for a band
struct GrooveSyncSession: Sendable {
    let groupId: String
    let leaderId: String
    let leaderName: String
    let startedAt: Date
    let lastActivityAt: Date
    let currentSong: SharedSong?

    init(groupId: String, leaderId: String, leaderName: String,
         startedAt: Date = Date(), lastActivityAt: Date = Date(),
         currentSong: SharedSong? = nil) {
        self.groupId = groupId
        self.leaderId = leaderId
        self.leaderName = leaderName
        self.startedAt = startedAt
        self.lastActivityAt = lastActivityAt
        self.currentSong = currentSong
    }

    init?(groupId: String, from data: [String: Any]) {
        guard let leaderId = data["leaderId"] as? String,
              let leaderName = data["leaderName"] as? String else {
            return nil
        }
        self.groupId = groupId
        self.leaderId = leaderId
        self.leaderName = leaderName
        self.startedAt = (data["startedAt"] as? Timestamp)?.dateValue() ?? Date()
        self.lastActivityAt = (data["lastActivityAt"] as? Timestamp)?.dateValue() ?? Date()

        if let songData = data["currentSong"] as? [String: Any] {
            self.currentSong = SharedSong(from: songData)
        } else {
            self.currentSong = nil
        }
    }
}

enum GrooveSyncService {
    private static var db: Firestore { Firestore.firestore() }

    /// Get the session document reference for a group
    private static func sessionRef(groupId: String) -> DocumentReference {
        db.collection("groups").document(groupId).collection("session").document("current")
    }

    // MARK: - Subscribe

    /// Subscribe to session changes for a group
    static func subscribeToSession(
        groupId: String,
        callback: @escaping (GrooveSyncSession?) -> Void
    ) -> ListenerRegistration {
        sessionRef(groupId: groupId).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Groove Sync listen error: \(error)")
                callback(nil)
                return
            }

            guard let data = snapshot?.data(), !data.isEmpty else {
                callback(nil)
                return
            }

            let session = GrooveSyncSession(groupId: groupId, from: data)
            callback(session)
        }
    }

    /// Subscribe to sessions for multiple groups (for showing "join" banner)
    static func subscribeToSessions(
        groupIds: [String],
        callback: @escaping ([GrooveSyncSession]) -> Void
    ) -> [ListenerRegistration] {
        guard !groupIds.isEmpty else {
            callback([])
            return []
        }

        var sessions: [String: GrooveSyncSession] = [:]
        var listeners: [ListenerRegistration] = []

        for groupId in groupIds {
            let listener = subscribeToSession(groupId: groupId) { session in
                if let session = session {
                    sessions[groupId] = session
                } else {
                    sessions.removeValue(forKey: groupId)
                }
                callback(Array(sessions.values))
            }
            listeners.append(listener)
        }

        return listeners
    }

    // MARK: - Leader Operations

    /// Start a new Groove Sync session
    static func startSession(groupId: String, userId: String, userName: String) async throws {
        print("🎵 GrooveSyncService.startSession - groupId: \(groupId), userId: \(userId)")
        let ref = sessionRef(groupId: groupId)
        print("🎵 Writing to path: \(ref.path)")

        let data: [String: Any] = [
            "leaderId": userId,
            "leaderName": userName,
            "startedAt": FieldValue.serverTimestamp(),
            "lastActivityAt": FieldValue.serverTimestamp(),
            "currentSong": NSNull()
        ]

        try await ref.setData(data)
        print("🎵 ✅ Started Groove Sync session in group \(groupId)")
    }

    /// Update the current song being shared
    static func updateCurrentSong(groupId: String, song: SharedSong) async throws {
        let data: [String: Any] = [
            "currentSong": song.toFirestoreData(),
            "lastActivityAt": FieldValue.serverTimestamp()
        ]
        try await sessionRef(groupId: groupId).updateData(data)
        print("🎵 Synced song: \(song.title) in \(song.concertKey)")
    }

    /// Update last activity timestamp (for timeout tracking)
    static func touchActivity(groupId: String) async throws {
        try await sessionRef(groupId: groupId).updateData([
            "lastActivityAt": FieldValue.serverTimestamp()
        ])
    }

    /// End the Groove Sync session
    static func endSession(groupId: String) async throws {
        try await sessionRef(groupId: groupId).delete()
        print("🎵 Ended Groove Sync session in group \(groupId)")
    }

    // MARK: - Follower Operations

    /// Update member's following status
    static func setFollowing(groupId: String, userId: String, isFollowing: Bool) async throws {
        let memberRef = db.collection("groups").document(groupId)
            .collection("members").document(userId)
        try await memberRef.updateData([
            "isFollowing": isFollowing,
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }

    /// Update member's last active timestamp
    static func touchMemberActivity(groupId: String, userId: String) async throws {
        let memberRef = db.collection("groups").document(groupId)
            .collection("members").document(userId)
        try await memberRef.updateData([
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }
}
