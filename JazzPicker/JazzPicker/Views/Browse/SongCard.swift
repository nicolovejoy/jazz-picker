//
//  SongCard.swift
//  JazzPicker
//

import SwiftUI

struct SongCard: View {
    @Environment(CachedKeysStore.self) private var cachedKeysStore
    @Environment(PDFCacheService.self) private var pdfCacheService
    let song: Song
    let instrument: Instrument
    let onTap: (String) -> Void  // Called with the selected concert key

    /// Check if default key PDF is cached
    private var isDefaultKeyCached: Bool {
        pdfCacheService.isCached(
            songTitle: song.title,
            concertKey: song.defaultKey,
            transposition: instrument.transposition,
            clef: instrument.clef
        )
    }

    /// Get ordered keys: standard (always first), sticky (if exists, 2nd), then others by recency
    private var orderedKeys: [(key: String, isStandard: Bool, isSticky: Bool)] {
        var result: [(key: String, isStandard: Bool, isSticky: Bool)] = []

        // Always add standard key first
        result.append((song.defaultKey, true, false))

        // Get cached keys (already ordered with sticky first)
        let cachedKeys = cachedKeysStore.getCachedKeys(for: song)
        let stickyKey = cachedKeysStore.getStickyKey(for: song)

        for key in cachedKeys {
            let isSticky = key == stickyKey
            result.append((key, false, isSticky))
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title area - tappable for default key
            HStack(alignment: .top) {
                Text(song.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer()

                // Subtle cache indicator
                if isDefaultKeyCached {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(song.defaultKey)
            }

            Spacer()

            // Key pills row
            HStack(spacing: 6) {
                ForEach(Array(orderedKeys.enumerated()), id: \.offset) { _, keyInfo in
                    KeyPillButton(
                        concertKey: keyInfo.key,
                        instrument: instrument,
                        isStandard: keyInfo.isStandard,
                        isSticky: keyInfo.isSticky
                    ) {
                        onTap(keyInfo.key)
                    }
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// A tappable key pill with standard (green) or cached (orange) styling
struct KeyPillButton: View {
    let concertKey: String
    let instrument: Instrument
    let isStandard: Bool
    let isSticky: Bool
    let onTap: () -> Void

    private var displayText: String {
        let formatted = formatKey(concertKey)

        if instrument.transposition == .C {
            return formatted
        } else {
            let written = transposeKey(concertKey, for: instrument.transposition)
            return "\(written) (\(formatted))"
        }
    }

    private var backgroundColor: Color {
        if isStandard {
            return Color.green.opacity(0.2)
        } else {
            return Color.orange.opacity(isSticky ? 0.35 : 0.2)
        }
    }

    private var foregroundColor: Color {
        if isStandard {
            return Color.green
        } else {
            return Color.orange
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(.caption)
                .fontWeight(isSticky ? .semibold : .regular)
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func formatKey(_ key: String) -> String {
        let isMinor = key.hasSuffix("m")
        let pitchPart = isMinor ? String(key.dropLast()) : key

        var result = pitchPart.prefix(1).uppercased()

        if pitchPart.count > 1 {
            let modifier = pitchPart.dropFirst()
            if modifier == "f" {
                result += "b"
            } else if modifier == "s" {
                result += "#"
            }
        }

        return isMinor ? result + "m" : result
    }

    private func transposeKey(_ concertKey: String, for transposition: Transposition) -> String {
        let keys = ["c", "df", "d", "ef", "e", "f", "gf", "g", "af", "a", "bf", "b"]

        let isMinor = concertKey.hasSuffix("m")
        let pitchClass = isMinor ? String(concertKey.dropLast()).lowercased() : concertKey.lowercased()

        guard let index = keys.firstIndex(of: pitchClass) else {
            return formatKey(concertKey)
        }

        let semitones: Int
        switch transposition {
        case .C: semitones = 0
        case .Bb: semitones = 2
        case .Eb: semitones = 9
        }

        let newIndex = (index + semitones) % 12
        let transposedPitch = keys[newIndex]
        return formatKey(isMinor ? transposedPitch + "m" : transposedPitch)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 16) {
        SongCard(
            song: Song(title: "Blue Bossa", defaultKey: "c", composer: nil, lowNoteMidi: nil, highNoteMidi: nil),
            instrument: .trumpet
        ) { key in
            print("Selected \(key)")
        }
        SongCard(
            song: Song(title: "Autumn Leaves", defaultKey: "g", composer: nil, lowNoteMidi: nil, highNoteMidi: nil),
            instrument: .piano
        ) { key in
            print("Selected \(key)")
        }
    }
    .padding()
    .environment(CachedKeysStore())
    .environment(PDFCacheService.shared)
}
