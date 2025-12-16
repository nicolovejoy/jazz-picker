//
//  BandFirestoreService.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation

enum BandFirestoreService {
    private static let collection = "groups"
    private static let membersSubcollection = "members"
    private static var db: Firestore { Firestore.firestore() }

    // MARK: - Create Band

    static func createBand(name: String, creatorId: String) async throws -> Band {
        // Generate unique code (collision is extremely unlikely with ~125k combinations)
        var code = JazzSlug.generate()

        // Try collision check, but don't fail if offline - just proceed
        do {
            var attempts = 0
            while attempts < 3 {
                if try await getBandByCode(code) == nil { break }
                code = JazzSlug.generate()
                attempts += 1
            }
        } catch {
            // Offline or query failed - proceed with generated code
            // Collision probability is ~0.0008% for first 100 bands
        }

        // Create band document
        let bandRef = db.collection(collection).document()
        let bandData: [String: Any] = [
            "name": name,
            "code": code,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await bandRef.setData(bandData)

        // Add creator as admin
        let memberRef = bandRef.collection(membersSubcollection).document(creatorId)
        try await memberRef.setData([
            "role": BandRole.admin.rawValue,
            "joinedAt": FieldValue.serverTimestamp()
        ])

        // Update user's groups array
        let userRef = db.collection("users").document(creatorId)
        try await userRef.updateData([
            "groups": FieldValue.arrayUnion([bandRef.documentID]),
            "lastUsedGroupId": bandRef.documentID,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return Band(id: bandRef.documentID, name: name, code: code)
    }

    // MARK: - Query

    static func getBandByCode(_ code: String) async throws -> Band? {
        let snapshot = try await db.collection(collection)
            .whereField("code", isEqualTo: code.lowercased())
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return Band(id: doc.documentID, from: doc.data())
    }

    static func getBand(_ id: String) async throws -> Band? {
        let doc = try await db.collection(collection).document(id).getDocument()
        guard let data = doc.data() else { return nil }
        return Band(id: doc.documentID, from: data)
    }

    // MARK: - Membership

    static func getBandMembers(_ bandId: String) async throws -> [BandMember] {
        let snapshot = try await db.collection(collection)
            .document(bandId)
            .collection(membersSubcollection)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            BandMember(userId: doc.documentID, from: doc.data())
        }.sorted { $0.joinedAt < $1.joinedAt }
    }

    static func joinBand(code: String, userId: String) async throws -> Band {
        guard let band = try await getBandByCode(code) else {
            throw BandError.bandNotFound
        }

        // Check if already member
        let memberRef = db.collection(collection)
            .document(band.id)
            .collection(membersSubcollection)
            .document(userId)
        let memberDoc = try await memberRef.getDocument()
        if memberDoc.exists {
            throw BandError.alreadyMember
        }

        // Add as member
        try await memberRef.setData([
            "role": BandRole.member.rawValue,
            "joinedAt": FieldValue.serverTimestamp()
        ])

        // Update user's groups
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "groups": FieldValue.arrayUnion([band.id]),
            "lastUsedGroupId": band.id,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        return band
    }

    static func leaveBand(bandId: String, userId: String) async throws {
        let members = try await getBandMembers(bandId)
        guard let member = members.first(where: { $0.userId == userId }) else {
            throw BandError.notMember
        }

        // Check sole admin
        let admins = members.filter { $0.role == .admin }
        if member.role == .admin && admins.count == 1 {
            throw BandError.soleAdmin
        }

        // Remove from members
        let memberRef = db.collection(collection)
            .document(bandId)
            .collection(membersSubcollection)
            .document(userId)
        try await memberRef.delete()

        // Update user's groups
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "groups": FieldValue.arrayRemove([bandId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    static func deleteBand(bandId: String, userId: String) async throws {
        let members = try await getBandMembers(bandId)

        // Can only delete if you're the only member
        guard members.count == 1, members.first?.userId == userId else {
            throw BandError.cannotDelete
        }

        // Delete band document FIRST (while member doc still exists for admin check)
        try await db.collection(collection).document(bandId).delete()

        // Delete the member document
        let memberRef = db.collection(collection)
            .document(bandId)
            .collection(membersSubcollection)
            .document(userId)
        try await memberRef.delete()

        // Update user's groups
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "groups": FieldValue.arrayRemove([bandId]),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - User Bands

    static func getUserBands(_ userId: String) async throws -> [Band] {
        // Get user document - use cache if available
        let userDoc = try await db.collection("users").document(userId).getDocument(source: .default)
        guard let bandIds = userDoc.data()?["groups"] as? [String], !bandIds.isEmpty else {
            return []
        }

        var bands: [Band] = []
        for id in bandIds {
            // Try to get each band, skip if fails
            if let band = try? await getBand(id) {
                bands.append(band)
            }
        }
        return bands
    }

    static func setLastUsedBand(userId: String, bandId: String) async throws {
        let userRef = db.collection("users").document(userId)
        try await userRef.updateData([
            "lastUsedGroupId": bandId,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}
