//
//  KeyPill.swift
//  JazzPicker
//

import SwiftUI

struct KeyPill: View {
    let concertKey: String
    let instrument: Instrument

    var displayText: String {
        let formatted = formatKey(concertKey)

        if instrument.transposition == .C {
            return formatted
        } else {
            let written = transposeKey(concertKey, for: instrument.transposition)
            return "\(written) (\(formatted))"
        }
    }

    var body: some View {
        Text(displayText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
    }

    private func formatKey(_ key: String) -> String {
        // Handle minor keys: "cm" -> "Cm", "afm" -> "Abm"
        let isMinor = key.hasSuffix("m")
        let pitchPart = isMinor ? String(key.dropLast()) : key

        // Convert "bf" to "Bb", "fs" to "F#", etc.
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

        // Strip minor suffix for transposition lookup
        let isMinor = concertKey.hasSuffix("m")
        let pitchClass = isMinor ? String(concertKey.dropLast()).lowercased() : concertKey.lowercased()

        guard let index = keys.firstIndex(of: pitchClass) else {
            return formatKey(concertKey)
        }

        let semitones: Int
        switch transposition {
        case .C: semitones = 0
        case .Bb: semitones = 2  // Up a major 2nd
        case .Eb: semitones = 9  // Up a major 6th
        }

        let newIndex = (index + semitones) % 12
        let transposedPitch = keys[newIndex]
        return formatKey(isMinor ? transposedPitch + "m" : transposedPitch)
    }
}

#Preview {
    VStack(spacing: 10) {
        KeyPill(concertKey: "c", instrument: .piano)
        KeyPill(concertKey: "cm", instrument: .piano)      // Minor key
        KeyPill(concertKey: "cm", instrument: .trumpet)    // Minor + transposed
        KeyPill(concertKey: "ef", instrument: .altoSax)
        KeyPill(concertKey: "bf", instrument: .piano)
    }
    .padding()
}
