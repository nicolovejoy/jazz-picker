//
//  SongRow.swift
//  JazzPicker
//

import SwiftUI

struct SongRow: View {
    let song: Song
    let instrument: Instrument
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        KeyPill(concertKey: song.defaultKey, instrument: instrument)
                    }
                }

                Spacer()

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
        SongRow(song: Song(title: "Blue Bossa", defaultKey: "c", lowNoteMidi: nil, highNoteMidi: nil), instrument: .trumpet) {}
        SongRow(song: Song(title: "Autumn Leaves", defaultKey: "g", lowNoteMidi: nil, highNoteMidi: nil), instrument: .piano) {}
    }
}
