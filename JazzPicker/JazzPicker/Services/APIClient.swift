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

    func generatePDF(
        song: String,
        concertKey: String,
        transposition: Transposition,
        clef: Clef,
        instrumentLabel: String?
    ) async throws -> GenerateResponse {
        let url = baseURL.appendingPathComponent("generate")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Normalize key format:
        // 1. Strip "m" suffix from minor keys (catalog stores "cm", API expects "c")
        // 2. Convert flat notation: catalog uses "eb", API expects "ef"
        var pitchClass = concertKey.hasSuffix("m") ? String(concertKey.dropLast()) : concertKey

        // Convert flat notation: "eb" → "ef", "ab" → "af", etc.
        if pitchClass.hasSuffix("b") && pitchClass.count == 2 {
            pitchClass = String(pitchClass.dropLast()) + "f"
        }

        var body: [String: Any] = [
            "song": song,
            "concert_key": pitchClass,
            "transposition": transposition.rawValue,
            "clef": clef.rawValue
        ]

        if let label = instrumentLabel {
            body["instrument_label"] = label
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🌐 API Request: \(song) in \(pitchClass) for \(transposition.rawValue)")

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
