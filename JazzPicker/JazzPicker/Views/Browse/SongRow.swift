//
//  SongRow.swift
//  JazzPicker
//

import SwiftUI

struct SongRow: View {
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    let song: Song
    let instrument: Instrument
    let onTap: () -> Void

    private var standardKey: String { song.defaultKey }
    private var preferredKey: String {
        cachedKeysStore.getStickyKey(for: song) ?? song.defaultKey
    }
    private var hasPreference: Bool { preferredKey != standardKey }

    /// Display title: part name if available (for grouped display), otherwise full title
    private var displayTitle: String {
        song.partName ?? song.title
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(displayTitle)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                // Keys: standard, preferred in parens if different
                HStack(spacing: 4) {
                    Text(displayKey(standardKey))
                        .foregroundStyle(.secondary)

                    if hasPreference {
                        Text("(\(displayKey(preferredKey)))")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.subheadline)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Format key for display, accounting for instrument transposition
    private func displayKey(_ concertKey: String) -> String {
        let isMinor = concertKey.hasSuffix("m")
        let baseKey = isMinor ? String(concertKey.dropLast()) : concertKey

        let displayBase: String
        if instrument.transposition == .C {
            displayBase = formatPitch(baseKey)
        } else {
            displayBase = formatPitch(transposeKey(baseKey, for: instrument.transposition))
        }

        return isMinor ? "\(displayBase) Minor" : "\(displayBase) Major"
    }

    /// Format pitch class: "bf" -> "Bb", "fs" -> "F#"
    private func formatPitch(_ pitch: String) -> String {
        var result = pitch.prefix(1).uppercased()
        if pitch.count > 1 {
            let modifier = pitch.dropFirst()
            if modifier == "f" {
                result += "b"
            } else if modifier == "s" {
                result += "#"
            }
        }
        return result
    }

    /// Transpose concert pitch to written pitch
    private func transposeKey(_ concertKey: String, for transposition: Transposition) -> String {
        let keys = ["c", "df", "d", "ef", "e", "f", "gf", "g", "af", "a", "bf", "b"]
        let pitchClass = concertKey.lowercased()

        guard let index = keys.firstIndex(of: pitchClass) else {
            return concertKey
        }

        let semitones: Int
        switch transposition {
        case .C: semitones = 0
        case .Bb: semitones = 2
        case .Eb: semitones = 9
        }

        let newIndex = (index + semitones) % 12
        return keys[newIndex]
    }
}

#Preview {
    List {
        SongRow(song: Song(title: "Blue Bossa", defaultKey: "cm", composer: "Kenny Dorham", lowNoteMidi: nil, highNoteMidi: nil, scoreId: nil, partName: nil, tempoStyle: nil, tempoSource: nil, tempoBpm: nil, tempoNoteValue: nil, timeSignature: nil), instrument: .trumpet) {}
        SongRow(song: Song(title: "Autumn Leaves", defaultKey: "gm", composer: "Joseph Kosma", lowNoteMidi: nil, highNoteMidi: nil, scoreId: nil, partName: nil, tempoStyle: nil, tempoSource: nil, tempoBpm: nil, tempoNoteValue: nil, timeSignature: nil), instrument: .piano) {}
    }
    .environmentObject(CachedKeysStore())
}
