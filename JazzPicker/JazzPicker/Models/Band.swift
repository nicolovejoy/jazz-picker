//
//  Band.swift
//  JazzPicker
//

import FirebaseFirestore
import Foundation

enum BandRole: String, Codable, Sendable {
    case admin
    case member
}

struct BandMember: Identifiable, Sendable {
    let userId: String
    let role: BandRole
    let joinedAt: Date

    var id: String { userId }

    init(userId: String, role: BandRole, joinedAt: Date = Date()) {
        self.userId = userId
        self.role = role
        self.joinedAt = joinedAt
    }

    init?(userId: String, from data: [String: Any]) {
        guard let roleString = data["role"] as? String,
              let role = BandRole(rawValue: roleString) else {
            return nil
        }
        self.userId = userId
        self.role = role
        self.joinedAt = (data["joinedAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}

struct Band: Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var code: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String = UUID().uuidString, name: String, code: String,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init?(id: String, from data: [String: Any]) {
        guard let name = data["name"] as? String,
              let code = data["code"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.code = code
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    func toFirestoreData() -> [String: Any] {
        [
            "name": name,
            "code": code,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: Date())
        ]
    }
}

enum BandError: LocalizedError {
    case bandNotFound
    case alreadyMember
    case notMember
    case soleAdmin
    case cannotDelete
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .bandNotFound: return "Band not found"
        case .alreadyMember: return "Already a member of this band"
        case .notMember: return "Not a member of this band"
        case .soleAdmin: return "Cannot leave as the only admin. Promote another member first."
        case .cannotDelete: return "Can only delete a band when you're the only member"
        case .notAuthenticated: return "You must be signed in"
        }
    }
}
