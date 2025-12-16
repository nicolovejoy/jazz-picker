//
//  BandStore.swift
//  JazzPicker
//

import Foundation
import Observation

@Observable
class BandStore {
    private(set) var bands: [Band] = []
    private(set) var isLoading = false
    private(set) var error: String?

    @ObservationIgnored
    private var currentUserId: String?

    // MARK: - Loading

    func loadBands(userId: String) async {
        currentUserId = userId
        isLoading = true
        error = nil

        do {
            bands = try await BandFirestoreService.getUserBands(userId)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        guard let userId = currentUserId else { return }
        await loadBands(userId: userId)
    }

    func clear() {
        bands = []
        currentUserId = nil
        isLoading = false
        error = nil
    }

    // MARK: - Create Band (Optimistic UI)

    func createBand(name: String, userId: String) async -> Band? {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        error = nil

        // Optimistic: add placeholder
        let tempId = UUID().uuidString
        let tempCode = JazzSlug.generate()
        let tempBand = Band(id: tempId, name: name, code: tempCode)
        bands.insert(tempBand, at: 0)

        do {
            let band = try await BandFirestoreService.createBand(name: name, creatorId: userId)
            // Replace temp with real
            bands.removeAll { $0.id == tempId }
            bands.insert(band, at: 0)
            return band
        } catch {
            // Rollback
            bands.removeAll { $0.id == tempId }
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Join Band

    func joinBand(code: String, userId: String) async -> Band? {
        let normalizedCode = JazzSlug.normalize(code)
        guard JazzSlug.isValid(normalizedCode) else {
            error = "Invalid band code format"
            return nil
        }

        error = nil

        do {
            let band = try await BandFirestoreService.joinBand(code: normalizedCode, userId: userId)
            bands.insert(band, at: 0)
            return band
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    // MARK: - Leave Band (Optimistic UI)

    func leaveBand(_ bandId: String, userId: String) async -> Bool {
        error = nil

        guard let index = bands.firstIndex(where: { $0.id == bandId }) else { return false }
        let backup = bands[index]
        bands.remove(at: index)

        do {
            try await BandFirestoreService.leaveBand(bandId: bandId, userId: userId)
            return true
        } catch {
            // Rollback
            bands.insert(backup, at: min(index, bands.count))
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Delete Band (when sole member)

    func deleteBand(_ bandId: String, userId: String) async -> Bool {
        error = nil

        guard let index = bands.firstIndex(where: { $0.id == bandId }) else { return false }
        let backup = bands[index]
        bands.remove(at: index)

        do {
            try await BandFirestoreService.deleteBand(bandId: bandId, userId: userId)
            return true
        } catch {
            // Rollback
            bands.insert(backup, at: min(index, bands.count))
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Members

    func getMembers(_ bandId: String) async -> [BandMember] {
        do {
            return try await BandFirestoreService.getBandMembers(bandId)
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    func getMemberCount(_ bandId: String) async -> Int {
        let members = await getMembers(bandId)
        return members.count
    }

    // MARK: - Error Handling

    func clearError() {
        error = nil
    }
}
