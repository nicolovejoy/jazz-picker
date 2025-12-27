//
//  UserProfileStore.swift
//  JazzPicker
//

import Combine
import FirebaseFirestore
import Foundation

class UserProfileStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private var listener: ListenerRegistration?

    private var db: Firestore {
        Firestore.firestore()
    }

    private var hasMigratedStickyKeys = false
    private let stickyKeysMigratedKey = "stickyKeysMigrated"
    private let legacyStickyKeysKey = "stickyKeys"

    private let cacheURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("userProfile.json")
    }()

    // MARK: - Listening

    func startListening(uid: String) {
        isLoading = true
        error = nil
        hasMigratedStickyKeys = false

        // Load from cache first for offline support
        if let cached = loadFromCache() {
            profile = cached
        }

        // Start Firestore listener
        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    // Only set error if we have no cached data
                    if self.profile == nil {
                        self.error = error.localizedDescription
                    }
                    return
                }

                guard let data = snapshot?.data() else {
                    // No profile exists yet — this is expected for new users
                    self.profile = nil
                    return
                }

                if let profile = UserProfile(from: data) {
                    self.profile = profile
                    self.saveToCache(profile)

                    // Migrate sticky keys from UserDefaults on first successful snapshot
                    if !self.hasMigratedStickyKeys {
                        self.hasMigratedStickyKeys = true
                        Task {
                            await self.migrateStickyKeysIfNeeded(uid: uid, currentProfile: profile)
                        }
                    }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        profile = nil
        isLoading = false
    }

    // MARK: - Create / Update

    func createProfile(uid: String, instrument: Instrument, displayName: String) async {
        isLoading = true
        error = nil

        let now = Date()
        let data: [String: Any] = [
            "instrument": instrument.rawValue,
            "displayName": displayName,
            "createdAt": Timestamp(date: now),
            "updatedAt": Timestamp(date: now)
        ]

        do {
            try await db.collection("users").document(uid).setData(data)
            // Profile will be updated via listener
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    func updateInstrument(uid: String, instrument: Instrument) async {
        error = nil

        let data: [String: Any] = [
            "instrument": instrument.rawValue,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users").document(uid).updateData(data)
            // Profile will be updated via listener
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearError() {
        error = nil
    }

    // MARK: - Preferred Keys Migration

    private func migrateStickyKeysIfNeeded(uid: String, currentProfile: UserProfile) async {
        // Check if already migrated
        if UserDefaults.standard.bool(forKey: stickyKeysMigratedKey) {
            return
        }

        // Check if there's legacy data to migrate
        guard let legacyKeys = UserDefaults.standard.dictionary(forKey: legacyStickyKeysKey) as? [String: String],
              !legacyKeys.isEmpty else {
            // No data to migrate, mark as done
            UserDefaults.standard.set(true, forKey: stickyKeysMigratedKey)
            return
        }

        // Only migrate if Firestore doesn't already have preferredKeys
        if currentProfile.preferredKeys != nil && !currentProfile.preferredKeys!.isEmpty {
            // Firestore already has data (maybe from another device), skip migration
            UserDefaults.standard.set(true, forKey: stickyKeysMigratedKey)
            UserDefaults.standard.removeObject(forKey: legacyStickyKeysKey)
            return
        }

        // Migrate to Firestore
        let data: [String: Any] = [
            "preferredKeys": legacyKeys,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users").document(uid).updateData(data)
            // Success - mark as migrated and delete legacy data
            UserDefaults.standard.set(true, forKey: stickyKeysMigratedKey)
            UserDefaults.standard.removeObject(forKey: legacyStickyKeysKey)
            print("Migrated \(legacyKeys.count) sticky keys to Firestore")
        } catch {
            // Migration failed, will retry on next app launch
            print("Failed to migrate sticky keys: \(error)")
        }
    }

    // MARK: - Preferred Keys

    func getPreferredKey(for songTitle: String) -> String? {
        profile?.preferredKeys?[songTitle]
    }

    /// Set or clear a preferred key for a song. Sparse storage: removes key if it matches default.
    func setPreferredKey(_ key: String, for songTitle: String, defaultKey: String, uid: String) async {
        var updatedKeys = profile?.preferredKeys ?? [:]

        // Sparse storage: only store if different from default
        if key == defaultKey {
            updatedKeys.removeValue(forKey: songTitle)
        } else {
            updatedKeys[songTitle] = key
        }

        // Update Firestore
        let data: [String: Any] = [
            "preferredKeys": updatedKeys,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users").document(uid).updateData(data)
            // Profile will be updated via listener
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearPreferredKey(for songTitle: String, uid: String) async {
        var updatedKeys = profile?.preferredKeys ?? [:]
        updatedKeys.removeValue(forKey: songTitle)

        let data: [String: Any] = [
            "preferredKeys": updatedKeys,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users").document(uid).updateData(data)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Preferred Octave Offsets

    func getPreferredOctaveOffset(for songTitle: String) -> Int? {
        profile?.preferredOctaveOffsets?[songTitle]
    }

    /// Set or clear a preferred octave offset for a song. Sparse storage: removes if offset is 0.
    func setPreferredOctaveOffset(_ offset: Int, for songTitle: String, uid: String) async {
        var updatedOffsets = profile?.preferredOctaveOffsets ?? [:]

        // Sparse storage: only store if non-zero
        if offset == 0 {
            updatedOffsets.removeValue(forKey: songTitle)
        } else {
            updatedOffsets[songTitle] = offset
        }

        // Update Firestore
        let data: [String: Any] = [
            "preferredOctaveOffsets": updatedOffsets,
            "updatedAt": Timestamp(date: Date())
        ]

        do {
            try await db.collection("users").document(uid).updateData(data)
            // Profile will be updated via listener
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Fetch Other Users

    /// Fetch display names for a list of user IDs.
    /// Returns a dictionary mapping userId to displayName (or email prefix if no displayName).
    func getDisplayNames(for userIds: [String]) async -> [String: String] {
        guard !userIds.isEmpty else { return [:] }

        var result: [String: String] = [:]

        // Firestore 'in' supports up to 30 values
        let limitedIds = Array(userIds.prefix(30))

        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: limitedIds)
                .getDocuments()

            for doc in snapshot.documents {
                let data = doc.data()
                if let displayName = data["displayName"] as? String, !displayName.isEmpty {
                    result[doc.documentID] = displayName
                } else if let email = data["email"] as? String {
                    result[doc.documentID] = String(email.split(separator: "@").first ?? "")
                } else {
                    result[doc.documentID] = String(doc.documentID.prefix(8)) + "..."
                }
            }

            // Fill in missing users with truncated ID
            for userId in userIds where result[userId] == nil {
                result[userId] = String(userId.prefix(8)) + "..."
            }
        } catch {
            // On error, fall back to truncated IDs
            for userId in userIds {
                result[userId] = String(userId.prefix(8)) + "..."
            }
        }

        return result
    }

    // MARK: - Cache

    private func loadFromCache() -> UserProfile? {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: cacheURL)
            return try JSONDecoder().decode(UserProfile.self, from: data)
        } catch {
            return nil
        }
    }

    private func saveToCache(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            try data.write(to: cacheURL)
        } catch {
            print("Failed to save profile cache: \(error)")
        }
    }

    func clearCache() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}
