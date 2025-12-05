//
//  PDFCacheService.swift
//  JazzPicker
//

import Foundation
import PDFKit
import Observation

/// Cached PDF metadata
struct CachedPDF: Codable, Identifiable {
    var id: String { cacheKey }

    let songTitle: String
    let concertKey: String
    let transposition: String
    let clef: String
    let cachedAt: Date
    let etag: String?
    let filePath: String  // relative to PDFCache directory
    let fileSize: Int64
    let cropBounds: CropBounds?

    var cacheKey: String {
        "\(songTitle)-\(concertKey)-\(transposition)-\(clef)"
    }
}

/// Result of a cache lookup
enum CacheResult {
    case hit(data: Data, crop: CropBounds?)
    case miss
    case stale(data: Data, crop: CropBounds?)  // Cached but should refresh
}

/// Manages local PDF caching with ETag-based freshness
@Observable
class PDFCacheService {
    static let shared = PDFCacheService()

    /// All cached PDFs (for UI display)
    private(set) var cachedPDFs: [CachedPDF] = []

    /// Total cache size in bytes
    private(set) var totalCacheSize: Int64 = 0

    /// Currently downloading items (for progress tracking)
    private(set) var downloadingKeys: Set<String> = []

    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("PDFCache", isDirectory: true)
    }

    private var manifestURL: URL {
        cacheDirectory.appendingPathComponent("manifest.json")
    }

    init() {
        ensureCacheDirectoryExists()
        loadManifest()
    }

    // MARK: - Public API

    /// Check if a PDF is cached for the given parameters
    func isCached(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) -> Bool {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        return cachedPDFs.contains { $0.cacheKey == key }
    }

    /// Get cached PDF if available
    func getCachedPDF(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) -> CacheResult {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)

        guard let cached = cachedPDFs.first(where: { $0.cacheKey == key }) else {
            return .miss
        }

        let fileURL = cacheDirectory.appendingPathComponent(cached.filePath)

        guard let data = try? Data(contentsOf: fileURL) else {
            // File missing, remove from manifest
            removeCachedPDF(key: key)
            return .miss
        }

        return .hit(data: data, crop: cached.cropBounds)
    }

    /// Get ETag for cached PDF (for conditional requests)
    func getETag(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) -> String? {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        return cachedPDFs.first { $0.cacheKey == key }?.etag
    }

    /// Cache a PDF
    func cachePDF(
        data: Data,
        songTitle: String,
        concertKey: String,
        transposition: Transposition,
        clef: Clef,
        etag: String?,
        cropBounds: CropBounds?
    ) {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        let fileName = "\(key).pdf"
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)

            // Remove old entry if exists
            cachedPDFs.removeAll { $0.cacheKey == key }

            let cached = CachedPDF(
                songTitle: songTitle,
                concertKey: concertKey,
                transposition: transposition.rawValue,
                clef: clef.rawValue,
                cachedAt: Date(),
                etag: etag,
                filePath: fileName,
                fileSize: Int64(data.count),
                cropBounds: cropBounds
            )

            cachedPDFs.append(cached)
            saveManifest()
            updateTotalSize()

            print("📦 Cached PDF: \(key) (\(formatBytes(Int64(data.count))))")
        } catch {
            print("❌ Failed to cache PDF: \(error)")
        }
    }

    /// Update ETag for existing cached PDF (after 304 response)
    func updateETag(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef, etag: String?) {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)

        if let index = cachedPDFs.firstIndex(where: { $0.cacheKey == key }) {
            let old = cachedPDFs[index]
            cachedPDFs[index] = CachedPDF(
                songTitle: old.songTitle,
                concertKey: old.concertKey,
                transposition: old.transposition,
                clef: old.clef,
                cachedAt: Date(),  // Update timestamp on revalidation
                etag: etag ?? old.etag,
                filePath: old.filePath,
                fileSize: old.fileSize,
                cropBounds: old.cropBounds
            )
            saveManifest()
        }
    }

    /// Clear all cached PDFs
    func clearCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            cachedPDFs = []
            totalCacheSize = 0
            saveManifest()
            print("🗑️ Cache cleared")
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }

    /// Get count of cached PDFs
    var cachedCount: Int {
        cachedPDFs.count
    }

    /// Format cache size for display
    var formattedCacheSize: String {
        formatBytes(totalCacheSize)
    }

    // MARK: - Download Tracking

    /// Mark a key as currently downloading
    func markDownloading(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        downloadingKeys.insert(key)
    }

    /// Mark download as complete
    func markDownloadComplete(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        downloadingKeys.remove(key)
    }

    /// Check if currently downloading
    func isDownloading(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) -> Bool {
        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        return downloadingKeys.contains(key)
    }

    // MARK: - Background Download

    /// Download and cache a PDF for offline use
    func downloadForOffline(
        songTitle: String,
        concertKey: String,
        transposition: Transposition,
        clef: Clef,
        instrumentLabel: String?
    ) async {
        // Skip if already cached or downloading
        if isCached(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef) {
            return
        }

        let key = cacheKey(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        if downloadingKeys.contains(key) {
            return
        }

        markDownloading(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        defer {
            markDownloadComplete(songTitle: songTitle, concertKey: concertKey, transposition: transposition, clef: clef)
        }

        do {
            // Get PDF URL from API
            let response = try await APIClient.shared.generatePDF(
                song: songTitle,
                concertKey: concertKey,
                transposition: transposition,
                clef: clef,
                instrumentLabel: instrumentLabel
            )

            guard let url = URL(string: response.url) else {
                print("❌ Invalid URL for \(songTitle)")
                return
            }

            // Download PDF
            let (data, httpResponse) = try await URLSession.shared.data(from: url)

            guard let httpResponse = httpResponse as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Download failed for \(songTitle)")
                return
            }

            let etag = httpResponse.value(forHTTPHeaderField: "ETag")

            // Cache it
            cachePDF(
                data: data,
                songTitle: songTitle,
                concertKey: concertKey,
                transposition: transposition,
                clef: clef,
                etag: etag,
                cropBounds: response.crop
            )

            print("⬇️ Downloaded for offline: \(songTitle) in \(concertKey)")

        } catch {
            print("❌ Failed to download \(songTitle): \(error)")
        }
    }

    /// Download multiple PDFs for offline use (e.g., for a setlist)
    func downloadSetlistForOffline(
        items: [(songTitle: String, concertKey: String)],
        transposition: Transposition,
        clef: Clef,
        instrumentLabel: String?
    ) async {
        for item in items {
            await downloadForOffline(
                songTitle: item.songTitle,
                concertKey: item.concertKey,
                transposition: transposition,
                clef: clef,
                instrumentLabel: instrumentLabel
            )
        }
    }

    // MARK: - Private

    private func cacheKey(songTitle: String, concertKey: String, transposition: Transposition, clef: Clef) -> String {
        "\(songTitle)-\(concertKey)-\(transposition.rawValue)-\(clef.rawValue)"
    }

    private func ensureCacheDirectoryExists() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadManifest() {
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            cachedPDFs = []
            return
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            cachedPDFs = try JSONDecoder().decode([CachedPDF].self, from: data)
            updateTotalSize()
            print("📦 Loaded \(cachedPDFs.count) cached PDFs (\(formattedCacheSize))")
        } catch {
            print("❌ Failed to load manifest: \(error)")
            cachedPDFs = []
        }
    }

    private func saveManifest() {
        do {
            let data = try JSONEncoder().encode(cachedPDFs)
            try data.write(to: manifestURL)
        } catch {
            print("❌ Failed to save manifest: \(error)")
        }
    }

    private func removeCachedPDF(key: String) {
        if let cached = cachedPDFs.first(where: { $0.cacheKey == key }) {
            let fileURL = cacheDirectory.appendingPathComponent(cached.filePath)
            try? fileManager.removeItem(at: fileURL)
        }
        cachedPDFs.removeAll { $0.cacheKey == key }
        saveManifest()
        updateTotalSize()
    }

    private func updateTotalSize() {
        totalCacheSize = cachedPDFs.reduce(0) { $0 + $1.fileSize }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
