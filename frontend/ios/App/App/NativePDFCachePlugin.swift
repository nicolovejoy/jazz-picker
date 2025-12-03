import Foundation
import Capacitor

@objc(NativePDFCachePlugin)
public class NativePDFCachePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "NativePDFCachePlugin"
    public let jsName = "NativePDFCache"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "downloadPdf", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCachedPath", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearCache", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCacheStats", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "refreshPdf", returnType: CAPPluginReturnPromise)
    ]

    private let cacheSubdirectory = "PDFCache"
    private let maxCacheAgeDays = 7

    private var cacheDirectory: URL? {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDir.appendingPathComponent(cacheSubdirectory, isDirectory: true)
    }

    private func ensureCacheDirectory() -> Bool {
        guard let cacheDir = cacheDirectory else { return false }

        if !FileManager.default.fileExists(atPath: cacheDir.path) {
            do {
                try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
                return true
            } catch {
                print("Failed to create cache directory: \(error)")
                return false
            }
        }
        return true
    }

    private func pdfPath(for cacheKey: String) -> URL? {
        return cacheDirectory?.appendingPathComponent("\(cacheKey).pdf")
    }

    private func metadataPath(for cacheKey: String) -> URL? {
        return cacheDirectory?.appendingPathComponent("\(cacheKey).json")
    }

    // MARK: - Metadata Handling

    private struct CacheMetadata: Codable {
        let cachedAt: String
        let crop: CropBoundsData?

        struct CropBoundsData: Codable {
            let top: Double
            let bottom: Double
            let left: Double
            let right: Double
        }
    }

    private func saveMetadata(for cacheKey: String, crop: [String: Any]?) {
        guard let metaPath = metadataPath(for: cacheKey) else { return }

        let isoFormatter = ISO8601DateFormatter()
        let cachedAt = isoFormatter.string(from: Date())

        var cropData: CacheMetadata.CropBoundsData?
        if let crop = crop,
           let top = crop["top"] as? Double,
           let bottom = crop["bottom"] as? Double,
           let left = crop["left"] as? Double,
           let right = crop["right"] as? Double {
            cropData = CacheMetadata.CropBoundsData(top: top, bottom: bottom, left: left, right: right)
        }

        let metadata = CacheMetadata(cachedAt: cachedAt, crop: cropData)

        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metaPath)
        } catch {
            print("Failed to save metadata: \(error)")
        }
    }

    private func loadMetadata(for cacheKey: String) -> CacheMetadata? {
        guard let metaPath = metadataPath(for: cacheKey),
              FileManager.default.fileExists(atPath: metaPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: metaPath)
            return try JSONDecoder().decode(CacheMetadata.self, from: data)
        } catch {
            print("Failed to load metadata: \(error)")
            return nil
        }
    }

    private func isCacheStale(metadata: CacheMetadata) -> Bool {
        let isoFormatter = ISO8601DateFormatter()
        guard let cachedDate = isoFormatter.date(from: metadata.cachedAt) else {
            return true // Can't parse date, consider stale
        }

        let ageInDays = Calendar.current.dateComponents([.day], from: cachedDate, to: Date()).day ?? 0
        return ageInDays > maxCacheAgeDays
    }

    // MARK: - Plugin Methods

    @objc func downloadPdf(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              let cacheKey = call.getString("cacheKey") else {
            call.reject("URL and cacheKey are required")
            return
        }

        let crop = call.getObject("crop")

        guard ensureCacheDirectory(),
              let pdfPath = pdfPath(for: cacheKey) else {
            call.reject("Failed to access cache directory")
            return
        }

        // Download on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let pdfData = try Data(contentsOf: url)
                try pdfData.write(to: pdfPath)

                // Save metadata with timestamp and crop bounds
                self.saveMetadata(for: cacheKey, crop: crop)

                DispatchQueue.main.async {
                    call.resolve([
                        "path": pdfPath.path,
                        "success": true
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    call.reject("Failed to download PDF: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func getCachedPath(_ call: CAPPluginCall) {
        guard let cacheKey = call.getString("cacheKey") else {
            call.reject("cacheKey is required")
            return
        }

        guard let pdfPath = pdfPath(for: cacheKey),
              FileManager.default.fileExists(atPath: pdfPath.path) else {
            call.resolve([
                "path": NSNull(),
                "isStale": false
            ])
            return
        }

        // Load metadata to check staleness and get crop bounds
        let metadata = loadMetadata(for: cacheKey)
        let isStale = metadata.map { isCacheStale(metadata: $0) } ?? false

        var result: [String: Any] = [
            "path": pdfPath.path,
            "isStale": isStale
        ]

        // Include crop bounds if available
        if let crop = metadata?.crop {
            result["crop"] = [
                "top": crop.top,
                "bottom": crop.bottom,
                "left": crop.left,
                "right": crop.right
            ]
        }

        if let cachedAt = metadata?.cachedAt {
            result["cachedAt"] = cachedAt
        }

        call.resolve(result)
    }

    @objc func refreshPdf(_ call: CAPPluginCall) {
        // Safe refresh: download to temp, then replace
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              let cacheKey = call.getString("cacheKey") else {
            call.reject("URL and cacheKey are required")
            return
        }

        let crop = call.getObject("crop")

        guard ensureCacheDirectory(),
              let pdfPath = pdfPath(for: cacheKey) else {
            call.reject("Failed to access cache directory")
            return
        }

        let tempPath = pdfPath.deletingLastPathComponent().appendingPathComponent("temp_\(cacheKey).pdf")

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Download to temp location
                let pdfData = try Data(contentsOf: url)
                try pdfData.write(to: tempPath)

                // 2. Remove old file if exists
                if FileManager.default.fileExists(atPath: pdfPath.path) {
                    try FileManager.default.removeItem(at: pdfPath)
                }

                // 3. Move temp to final location
                try FileManager.default.moveItem(at: tempPath, to: pdfPath)

                // 4. Update metadata
                self.saveMetadata(for: cacheKey, crop: crop)

                DispatchQueue.main.async {
                    call.resolve([
                        "path": pdfPath.path,
                        "success": true
                    ])
                }
            } catch {
                // Clean up temp file if it exists
                try? FileManager.default.removeItem(at: tempPath)

                DispatchQueue.main.async {
                    call.reject("Failed to refresh PDF: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func clearCache(_ call: CAPPluginCall) {
        guard let cacheDir = cacheDirectory else {
            call.reject("Failed to access cache directory")
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if FileManager.default.fileExists(atPath: cacheDir.path) {
                    try FileManager.default.removeItem(at: cacheDir)
                }
                // Recreate empty directory
                try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

                DispatchQueue.main.async {
                    call.resolve(["success": true])
                }
            } catch {
                DispatchQueue.main.async {
                    call.reject("Failed to clear cache: \(error.localizedDescription)")
                }
            }
        }
    }

    @objc func getCacheStats(_ call: CAPPluginCall) {
        guard let cacheDir = cacheDirectory else {
            call.resolve([
                "count": 0,
                "totalSizeBytes": 0
            ])
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            var count = 0
            var totalSize: UInt64 = 0

            if let enumerator = FileManager.default.enumerator(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if fileURL.pathExtension == "pdf" {
                        count += 1
                        if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            totalSize += UInt64(fileSize)
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                call.resolve([
                    "count": count,
                    "totalSizeBytes": totalSize
                ])
            }
        }
    }
}
