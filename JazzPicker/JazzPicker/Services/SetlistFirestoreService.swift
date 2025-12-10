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
        callback: @escaping ([Setlist]) -> Void
    ) -> ListenerRegistration {
        db.collection(collection)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
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

    // MARK: - Create

    static func createSetlist(name: String, ownerId: String) async throws -> String {
        let docRef = db.collection(collection).document()
        let data: [String: Any] = [
            "name": name,
            "ownerId": ownerId,
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
