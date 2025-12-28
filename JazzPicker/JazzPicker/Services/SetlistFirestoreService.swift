//
//  SetlistFirestoreService.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation

enum SetlistFirestoreService {
    private static let collection = "setlists"
    private static var db: Firestore { Firestore.firestore() }

    // MARK: - Subscribe

    static func subscribeToSetlists(
        groupIds: [String]?,
        callback: @escaping ([Setlist]) -> Void
    ) -> ListenerRegistration {
        // If groupIds is nil or empty, user has no groups -> no setlists
        // (nil means profile hasn't loaded yet OR user has no groups field)
        guard let ids = groupIds, !ids.isEmpty else {
            callback([])
            // Return a no-op listener that won't trigger permission errors
            // Using an impossible filter instead of limit-only query
            return db.collection(collection)
                .whereField("groupId", isEqualTo: "__no_groups__")
                .addSnapshotListener { _, _ in }
        }

        let limitedIds = Array(ids.prefix(30))  // Firestore 'in' limit
        let query = db.collection(collection)
            .whereField("groupId", in: limitedIds)
            .order(by: "updatedAt", descending: true)

        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Firestore listen error: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                callback([])
                return
            }

            let setlists = documents.compactMap { doc -> Setlist? in
                Setlist(id: doc.documentID, from: doc.data())
            }
            callback(setlists)
        }
    }

    // MARK: - Fetch

    static func getSetlist(id: String) async -> Setlist? {
        do {
            let doc = try await db.collection(collection).document(id).getDocument()
            guard let data = doc.data() else { return nil }
            return Setlist(id: doc.documentID, from: data)
        } catch {
            print("❌ Failed to fetch setlist: \(error)")
            return nil
        }
    }

    // MARK: - Create

    static func createSetlist(name: String, ownerId: String, groupId: String) async throws -> String {
        let docRef = db.collection(collection).document()
        let data: [String: Any] = [
            "name": name,
            "ownerId": ownerId,
            "groupId": groupId,
            "items": [],
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await docRef.setData(data)
        return docRef.documentID
    }

    // MARK: - Update

    static func updateSetlist(id: String, name: String? = nil, items: [SetlistItem]? = nil) async throws {
        var data: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let name = name {
            data["name"] = name
        }
        if let items = items {
            data["items"] = items.map { $0.toFirestoreData() }
        }
        try await db.collection(collection).document(id).updateData(data)
    }

    // MARK: - Delete

    static func deleteSetlist(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
}
