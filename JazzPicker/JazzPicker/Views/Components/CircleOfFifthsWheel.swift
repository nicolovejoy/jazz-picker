//
//  CircleOfFifthsWheel.swift
//  JazzPicker
//

import SwiftUI

/// A simple 12-key grid for selecting a new key
/// Arranged in circle-of-fifths order: C-G-D-A-E-B on top, F-Bb-Eb-Ab-Db-Gb on bottom
struct KeyPickerGrid: View {
    let currentKey: String
    let standardKey: String
    let onSelect: (String) -> Void

    /// Circle of fifths - top row (sharps direction)
    private let topRow = ["c", "g", "d", "a", "e", "b"]
    /// Circle of fifths - bottom row (flats direction)
    private let bottomRow = ["f", "bf", "ef", "af", "df", "gf"]

    /// Determine if we should use flat spelling based on the standard key
    private func shouldUseFlats(for key: String) -> Bool {
        let flatKeys = ["f", "bf", "ef", "af", "df", "gf", "c"]
        let baseKey = key.replacingOccurrences(of: "m", with: "")
        return flatKeys.contains(baseKey.lowercased())
    }

    /// Format a key for display with appropriate accidentals
    private func displayName(for key: String) -> String {
        let useFlats = shouldUseFlats(for: standardKey)

        let keyMap: [String: (flat: String, sharp: String)] = [
            "c": ("C", "C"),
            "df": ("Db", "C#"),
            "d": ("D", "D"),
            "ef": ("Eb", "D#"),
            "e": ("E", "E"),
            "f": ("F", "F"),
            "gf": ("Gb", "F#"),
            "g": ("G", "G"),
            "af": ("Ab", "G#"),
            "a": ("A", "A"),
            "bf": ("Bb", "A#"),
            "b": ("B", "B")
        ]

        guard let spellings = keyMap[key.lowercased()] else {
            return key.uppercased()
        }

        return useFlats ? spellings.flat : spellings.sharp
    }

    /// Check if this key matches the current key (handling enharmonics)
    private func isCurrentKey(_ key: String) -> Bool {
        let normalizedCurrent = normalizeKey(currentKey)
        let normalizedKey = normalizeKey(key)
        return normalizedCurrent == normalizedKey
    }

    private func normalizeKey(_ key: String) -> String {
        let enharmonics: [String: String] = [
            "cs": "df", "ds": "ef", "fs": "gf", "gs": "af", "as": "bf"
        ]
        let lower = key.lowercased()
        return enharmonics[lower] ?? lower
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: C G D A E B
            HStack(spacing: 8) {
                ForEach(topRow, id: \.self) { key in
                    KeyGridButton(
                        label: displayName(for: key),
                        isSelected: isCurrentKey(key)
                    ) {
                        onSelect(key)
                    }
                }
            }

            // Bottom row: F Bb Eb Ab Db Gb
            HStack(spacing: 8) {
                ForEach(bottomRow, id: \.self) { key in
                    KeyGridButton(
                        label: displayName(for: key),
                        isSelected: isCurrentKey(key)
                    ) {
                        onSelect(key)
                    }
                }
            }
        }
        .padding()
    }
}

/// Individual key button in the grid
struct KeyGridButton: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.system(size: 18, weight: isSelected ? .bold : .medium))
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

/// Bottom sheet presentation for the key picker
struct KeyPickerSheet: View {
    let currentKey: String
    let standardKey: String
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Handle
            Capsule()
                .fill(Color(.tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("Change Key")
                .font(.headline)

            Text("Tap a key to select")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            KeyPickerGrid(
                currentKey: currentKey,
                standardKey: standardKey
            ) { key in
                onConfirm(key)
                dismiss()
            }

            Spacer()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    VStack {
        KeyPickerGrid(
            currentKey: "g",
            standardKey: "g"
        ) { key in
            print("Selected: \(key)")
        }
    }
    .padding()
}
