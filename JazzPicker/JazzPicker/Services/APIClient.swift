//
//  APIClient.swift
//  JazzPicker
//

import Foundation

final class APIClient: Sendable {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://jazz-picker.fly.dev/api/v2")!

    func fetchCatalog() async throws -> [Song] {
        let url = baseURL.appendingPathComponent("catalog")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.invalidResponse(statusCode: code, body: "Catalog fetch failed")
        }

        let catalogResponse = try JSONDecoder().decode(CatalogResponse.self, from: data)
        return catalogResponse.songs
    }

    func getCachedKeys(song: String, transposition: Transposition, clef: Clef) async throws -> CachedKeysResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("songs/\(song)/cached"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "transposition", value: transposition.rawValue),
            URLQueryItem(name: "clef", value: clef.rawValue)
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.invalidResponse(statusCode: code, body: "Cached keys fetch failed")
        }

        return try JSONDecoder().decode(CachedKeysResponse.self, from: data)
    }

    func fetchAllCachedKeys(transposition: Transposition, clef: Clef) async throws -> BulkCachedKeysResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("cached-keys"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "transposition", value: transposition.rawValue),
            URLQueryItem(name: "clef", value: clef.rawValue)
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.invalidResponse(statusCode: code, body: "Bulk cached keys fetch failed")
        }

        return try JSONDecoder().decode(BulkCachedKeysResponse.self, from: data)
    }

    func generatePDF(
        song: String,
        concertKey: String,
        transposition: Transposition,
        clef: Clef,
        instrumentLabel: String?,
        octaveOffset: Int? = nil
    ) async throws -> GenerateResponse {
        let url = baseURL.appendingPathComponent("generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "song": song,
            "concert_key": concertKey,
            "transposition": transposition.rawValue,
            "clef": clef.rawValue
        ]

        if let label = instrumentLabel {
            body["instrument_label"] = label
        }

        // Only include octave_offset if explicitly set (nil = auto-calculate)
        if let offset = octaveOffset {
            body["octave_offset"] = offset
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 API Request: \(song) in \(concertKey) for \(transposition.rawValue) oct:\(octaveOffset.map { String($0) } ?? "auto")")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(statusCode: 0, body: "No HTTP response")
        }

        if httpResponse.statusCode != 200 {
            let bodyString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            print("🌐 API Error \(httpResponse.statusCode): \(bodyString)")
            throw APIError.invalidResponse(statusCode: httpResponse.statusCode, body: bodyString)
        }

        return try JSONDecoder().decode(GenerateResponse.self, from: data)
    }

    // MARK: - Setlist API

    func fetchSetlists() async throws -> [Setlist] {
        let url = baseURL.appendingPathComponent("setlists")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.invalidResponse(statusCode: code, body: body)
        }

        let apiResponse = try JSONDecoder().decode(SetlistsResponse.self, from: data)
        return apiResponse.setlists.compactMap { $0.toSetlist() }
    }

    func createSetlist(name: String, items: [SetlistItem] = [], deviceID: String) async throws -> Setlist {
        let url = baseURL.appendingPathComponent("setlists")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")

        let body: [String: Any] = [
            "name": name,
            "items": items.map { item in
                [
                    "song_title": item.songTitle,
                    "concert_key": item.concertKey,
                    "is_set_break": item.isSetBreak,
                    "octave_offset": item.octaveOffset
                ]
            }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 API: Creating setlist '\(name)'")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🌐 API Error \(code): \(body)")
            throw APIError.invalidResponse(statusCode: code, body: body)
        }

        let apiSetlist = try JSONDecoder().decode(APISetlist.self, from: data)
        guard let setlist = apiSetlist.toSetlist() else {
            throw APIError.invalidResponse(statusCode: 200, body: "Invalid setlist response")
        }
        return setlist
    }

    func updateSetlist(_ setlist: Setlist, deviceID: String) async throws -> Setlist {
        let url = baseURL.appendingPathComponent("setlists/\(setlist.id.uuidString.lowercased())")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceID, forHTTPHeaderField: "X-Device-ID")

        let body: [String: Any] = [
            "name": setlist.name,
            "items": setlist.items.map { item in
                [
                    "id": item.id.uuidString,
                    "song_title": item.songTitle,
                    "concert_key": item.concertKey,
                    "is_set_break": item.isSetBreak,
                    "octave_offset": item.octaveOffset
                ]
            }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 API: Updating setlist '\(setlist.name)'")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🌐 API Error \(code): \(body)")
            throw APIError.invalidResponse(statusCode: code, body: body)
        }

        let apiSetlist = try JSONDecoder().decode(APISetlist.self, from: data)
        guard let updated = apiSetlist.toSetlist() else {
            throw APIError.invalidResponse(statusCode: 200, body: "Invalid setlist response")
        }
        return updated
    }

    func deleteSetlist(id: UUID) async throws {
        let url = baseURL.appendingPathComponent("setlists/\(id.uuidString.lowercased())")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        print("🌐 API: Deleting setlist \(id)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🌐 API Error \(code): \(body)")
            throw APIError.invalidResponse(statusCode: code, body: body)
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidResponse(statusCode: Int, body: String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let code, let body):
            return "Server error \(code): \(body.prefix(200))"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Setlist API Response Types

struct SetlistsResponse: Codable {
    let setlists: [APISetlist]
}

struct APISetlist: Codable {
    let id: String
    let name: String
    let createdAt: String
    let updatedAt: String
    let createdByDevice: String?
    let items: [APISetlistItem]

    enum CodingKeys: String, CodingKey {
        case id, name, items
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdByDevice = "created_by_device"
    }

    func toSetlist() -> Setlist? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let created = dateFormatter.date(from: createdAt) ?? Date()
        let updated = dateFormatter.date(from: updatedAt) ?? Date()

        return Setlist(
            id: uuid,
            name: name,
            items: items.compactMap { $0.toSetlistItem() },
            createdAt: created,
            lastOpenedAt: updated,
            deletedAt: nil
        )
    }
}

struct APISetlistItem: Codable {
    let id: String
    let songTitle: String
    let concertKey: String
    let position: Int
    let isSetBreak: Bool
    let octaveOffset: Int?

    enum CodingKeys: String, CodingKey {
        case id, position
        case songTitle = "song_title"
        case concertKey = "concert_key"
        case isSetBreak = "is_set_break"
        case octaveOffset = "octave_offset"
    }

    func toSetlistItem() -> SetlistItem? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return SetlistItem(
            id: uuid,
            songTitle: songTitle,
            concertKey: concertKey,
            position: position,
            isSetBreak: isSetBreak,
            octaveOffset: octaveOffset ?? 0
        )
    }
}
