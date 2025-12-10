//
//  SongRow.swift
//  JazzPicker
//

import SwiftUI

struct SongRow: View {
    @Environment(PDFCacheService.self) private var pdfCacheService
    let song: Song
    let instrument: Instrument
    let onTap: () -> Void

    private var isCached: Bool {
        pdfCacheService.isCached(
            songTitle: song.title,
            concertKey: song.defaultKey,
            transposition: instrument.transposition,
            clef: instrument.clef
        )
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        KeyPill(concertKey: song.defaultKey, instrument: instrument)

                        if let composer = song.composer {
                            Text(composer)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                // Subtle cache indicator
                if isCached {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.4))
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        SongRow(song: Song(title: "Blue Bossa", defaultKey: "c", composer: "Kenny Dorham", lowNoteMidi: nil, highNoteMidi: nil), instrument: .trumpet) {}
        SongRow(song: Song(title: "Autumn Leaves", defaultKey: "g", composer: "Joseph Kosma", lowNoteMidi: nil, highNoteMidi: nil), instrument: .piano) {}
    }
    .environment(PDFCacheService.shared)
}
