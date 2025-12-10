//
//  UserProfileStore.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation
import Observation

@Observable
class UserProfileStore {
    private(set) var profile: UserProfile?
    private(set) var isLoading = false
    private(set) var error: String?

    @ObservationIgnored
    private var listener: ListenerRegistration?

    @ObservationIgnored
    private var db: Firestore {
        Firestore.firestore()
    }

    @ObservationIgnored
    private let cacheURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("userProfile.json")
    }()

    // MARK: - Listening

    func startListening(uid: String) {
        isLoading = true
        error = nil

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
