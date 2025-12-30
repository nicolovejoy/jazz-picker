//
//  SongCard.swift
//  JazzPicker
//

import SwiftUI

struct SongCard: View {
    @EnvironmentObject private var cachedKeysStore: CachedKeysStore
    let song: Song
    let instrument: Instrument
    let onTap: (String) -> Void  // Called with the selected concert key

    private var standardKey: String { song.defaultKey }
    private var preferredKey: String {
        cachedKeysStore.getStickyKey(for: song) ?? song.defaultKey
    }
    private var hasPreference: Bool { preferredKey != standardKey }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title and composer
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let composer = song.composer {
                    Text(composer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Keys row: standard key, preferred key in parens if different
            HStack(spacing: 4) {
                Button {
                    onTap(standardKey)
                } label: {
                    Text(displayKey(standardKey))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if hasPreference {
                    Text("(\(displayKey(preferredKey)))")
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(preferredKey)
        }
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
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320))], spacing: 16) {
        SongCard(
            song: Song(title: "Blue Bossa", defaultKey: "cm", composer: nil, lowNoteMidi: nil, highNoteMidi: nil, scoreId: nil, partName: nil, tempoStyle: nil, tempoSource: nil, tempoBpm: nil, tempoNoteValue: nil, timeSignature: nil),
            instrument: .trumpet
        ) { key in
            print("Selected \(key)")
        }
        SongCard(
            song: Song(title: "Autumn Leaves", defaultKey: "gm", composer: "Joseph Kosma", lowNoteMidi: nil, highNoteMidi: nil, scoreId: nil, partName: nil, tempoStyle: nil, tempoSource: nil, tempoBpm: nil, tempoNoteValue: nil, timeSignature: nil),
            instrument: .piano
        ) { key in
            print("Selected \(key)")
        }
    }
    .padding()
    .environmentObject(CachedKeysStore())
}
