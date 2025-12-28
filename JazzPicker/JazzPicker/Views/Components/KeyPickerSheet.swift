//
//  KeyPickerSheet.swift
//  JazzPicker
//

import SwiftUI

// MARK: - Ambitus Rendering

/// Represents a note's position on the staff
struct StaffNote {
    let diatonicPosition: Int  // 0 = C0, 1 = D0, 2 = E0, ... 7 = C1, etc.
    let accidental: Accidental

    enum Accidental: Equatable {
        case natural
        case sharp
        case flat
    }
}

/// Converts MIDI notes to staff positions
enum MidiToStaff {

    private static let pitchClassToSharp: [(diatonic: Int, accidental: StaffNote.Accidental)] = [
        (0, .natural),  // C
        (0, .sharp),    // C#
        (1, .natural),  // D
        (1, .sharp),    // D#
        (2, .natural),  // E
        (3, .natural),  // F
        (3, .sharp),    // F#
        (4, .natural),  // G
        (4, .sharp),    // G#
        (5, .natural),  // A
        (5, .sharp),    // A#
        (6, .natural),  // B
    ]

    private static let pitchClassToFlat: [(diatonic: Int, accidental: StaffNote.Accidental)] = [
        (0, .natural),  // C
        (1, .flat),     // Db
        (1, .natural),  // D
        (2, .flat),     // Eb
        (2, .natural),  // E
        (3, .natural),  // F
        (4, .flat),     // Gb
        (4, .natural),  // G
        (5, .flat),     // Ab
        (5, .natural),  // A
        (6, .flat),     // Bb
        (6, .natural),  // B
    ]

    static func staffNote(from midi: Int, useFlats: Bool = false) -> StaffNote {
        let octave = (midi / 12) - 1
        let pitchClass = midi % 12

        let mapping = useFlats ? pitchClassToFlat : pitchClassToSharp
        let (diatonicStep, accidental) = mapping[pitchClass]

        let diatonicPosition = octave * 7 + diatonicStep

        return StaffNote(diatonicPosition: diatonicPosition, accidental: accidental)
    }

    static func bottomLineDiatonic(for clef: AmbitusView.Clef) -> Int {
        switch clef {
        case .treble: return 30  // E4
        case .bass: return 18    // G2
        }
    }
}

/// Renders a musical staff showing the note range (ambitus) for a song
struct AmbitusView: View {
    let lowMidi: Int
    let highMidi: Int
    let clef: Clef
    let useFlats: Bool

    enum Clef { case treble, bass }

    init(lowMidi: Int, highMidi: Int, clef: Clef = .treble, useFlats: Bool = false) {
        self.lowMidi = lowMidi
        self.highMidi = highMidi
        self.clef = clef
        self.useFlats = useFlats
    }

    var body: some View {
        Canvas { context, size in
            let lineSpacing: CGFloat = 5
            let staffHeight = lineSpacing * 4
            let staffTop = (size.height - staffHeight) / 2
            let bottomLineY = staffTop + staffHeight

            // Draw 5 staff lines
            for i in 0..<5 {
                let y = staffTop + CGFloat(i) * lineSpacing
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: 2, y: y))
                        p.addLine(to: CGPoint(x: size.width - 2, y: y))
                    },
                    with: .color(.secondary.opacity(0.5)),
                    lineWidth: 0.5
                )
            }

            let noteRadius: CGFloat = lineSpacing * 0.45
            let bottomLineDiatonic = MidiToStaff.bottomLineDiatonic(for: clef)

            drawNote(context: context, midi: lowMidi, x: size.width * 0.35,
                     bottomLineY: bottomLineY, bottomLineDiatonic: bottomLineDiatonic,
                     lineSpacing: lineSpacing, noteRadius: noteRadius)

            drawNote(context: context, midi: highMidi, x: size.width * 0.65,
                     bottomLineY: bottomLineY, bottomLineDiatonic: bottomLineDiatonic,
                     lineSpacing: lineSpacing, noteRadius: noteRadius)
        }
    }

    private func drawNote(context: GraphicsContext, midi: Int, x: CGFloat,
                          bottomLineY: CGFloat, bottomLineDiatonic: Int,
                          lineSpacing: CGFloat, noteRadius: CGFloat) {
        let staffNote = MidiToStaff.staffNote(from: midi, useFlats: useFlats)
        let stepsFromBottom = staffNote.diatonicPosition - bottomLineDiatonic
        let y = bottomLineY - (CGFloat(stepsFromBottom) * lineSpacing / 2)

        drawLedgerLines(context: context, stepsFromBottom: stepsFromBottom,
                        x: x, bottomLineY: bottomLineY, lineSpacing: lineSpacing,
                        noteRadius: noteRadius)

        if staffNote.accidental != .natural {
            drawAccidental(context: context, accidental: staffNote.accidental,
                           x: x - noteRadius * 2.5, y: y, lineSpacing: lineSpacing)
        }

        // Note head
        var notePath = Ellipse().path(in: CGRect(
            x: -noteRadius,
            y: -noteRadius * 0.75,
            width: noteRadius * 2,
            height: noteRadius * 1.5
        ))
        let transform = CGAffineTransform(translationX: x, y: y)
            .rotated(by: -0.3)
        notePath = notePath.applying(transform)
        context.fill(notePath, with: .color(.primary))
    }

    private func drawLedgerLines(context: GraphicsContext, stepsFromBottom: Int,
                                  x: CGFloat, bottomLineY: CGFloat,
                                  lineSpacing: CGFloat, noteRadius: CGFloat) {
        let ledgerWidth = noteRadius * 3

        if stepsFromBottom < 0 {
            var step = -2
            while step >= stepsFromBottom {
                let y = bottomLineY - (CGFloat(step) * lineSpacing / 2)
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x - ledgerWidth / 2, y: y))
                        p.addLine(to: CGPoint(x: x + ledgerWidth / 2, y: y))
                    },
                    with: .color(.primary),
                    lineWidth: 0.5
                )
                step -= 2
            }
        }

        if stepsFromBottom > 8 {
            var step = 10
            while step <= stepsFromBottom {
                let y = bottomLineY - (CGFloat(step) * lineSpacing / 2)
                context.stroke(
                    Path { p in
                        p.move(to: CGPoint(x: x - ledgerWidth / 2, y: y))
                        p.addLine(to: CGPoint(x: x + ledgerWidth / 2, y: y))
                    },
                    with: .color(.primary),
                    lineWidth: 0.5
                )
                step += 2
            }
        }
    }

    private func drawAccidental(context: GraphicsContext, accidental: StaffNote.Accidental,
                                 x: CGFloat, y: CGFloat, lineSpacing: CGFloat) {
        let symbol = accidental == .sharp ? "♯" : "♭"
        context.draw(
            Text(symbol).font(.system(size: lineSpacing * 2)),
            at: CGPoint(x: x, y: y),
            anchor: .center
        )
    }
}

// MARK: - Key Transposition

/// Semitone values for each key (C = 0)
private let keySemitones: [String: Int] = [
    "c": 0, "cs": 1, "df": 1, "d": 2, "ds": 3, "ef": 3,
    "e": 4, "f": 5, "fs": 6, "gf": 6, "g": 7, "gs": 8,
    "af": 8, "a": 9, "as": 10, "bf": 10, "b": 11
]

/// Calculate semitone offset between two keys
private func semitoneOffset(from sourceKey: String, to targetKey: String) -> Int {
    let sourceBase = sourceKey.replacingOccurrences(of: "m", with: "").lowercased()
    let targetBase = targetKey.replacingOccurrences(of: "m", with: "").lowercased()

    guard let sourceSemitone = keySemitones[sourceBase],
          let targetSemitone = keySemitones[targetBase] else {
        return 0
    }

    return targetSemitone - sourceSemitone
}

// MARK: - Key Picker Grid

/// A 12-key grid for selecting a new key, with optional ambitus display
/// Arranged in circle-of-fifths order: C-G-D-A-E-B on top, F-Bb-Eb-Ab-Db-Gb on bottom
struct KeyPickerGrid: View {
    let currentKey: String
    let standardKey: String
    let songRange: (low: Int, high: Int)?  // MIDI range in standard key
    let onSelect: (String) -> Void

    init(currentKey: String, standardKey: String, songRange: (low: Int, high: Int)? = nil,
         onSelect: @escaping (String) -> Void) {
        self.currentKey = currentKey
        self.standardKey = standardKey
        self.songRange = songRange
        self.onSelect = onSelect
    }

    private let topRow = ["c", "g", "d", "a", "e", "b"]
    private let bottomRow = ["f", "bf", "ef", "af", "df", "gf"]

    private func shouldUseFlats(for key: String) -> Bool {
        let flatKeys = ["f", "bf", "ef", "af", "df", "gf", "c"]
        let baseKey = key.replacingOccurrences(of: "m", with: "")
        return flatKeys.contains(baseKey.lowercased())
    }

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

    private func isCurrentKey(_ key: String) -> Bool {
        normalizeKey(currentKey) == normalizeKey(key)
    }

    private func isStandardKey(_ key: String) -> Bool {
        normalizeKey(standardKey.replacingOccurrences(of: "m", with: "")) == normalizeKey(key)
    }

    private func normalizeKey(_ key: String) -> String {
        let enharmonics: [String: String] = [
            "cs": "df", "ds": "ef", "fs": "gf", "gs": "af", "as": "bf"
        ]
        let lower = key.lowercased()
        return enharmonics[lower] ?? lower
    }

    /// Calculate transposed range for a target key
    private func transposedRange(for targetKey: String) -> (low: Int, high: Int)? {
        guard let range = songRange else { return nil }
        let offset = semitoneOffset(from: standardKey, to: targetKey)
        return (range.low + offset, range.high + offset)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Top row: C G D A E B (sharps direction)
            HStack(spacing: 6) {
                ForEach(topRow, id: \.self) { key in
                    KeyGridButton(
                        label: displayName(for: key),
                        isSelected: isCurrentKey(key),
                        isStandard: isStandardKey(key),
                        ambitus: transposedRange(for: key),
                        useFlats: false
                    ) {
                        onSelect(key)
                    }
                }
                // Treble clef indicator
                if songRange != nil {
                    Text("𝄞")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
            }

            // Bottom row: F Bb Eb Ab Db Gb (flats direction)
            HStack(spacing: 6) {
                ForEach(bottomRow, id: \.self) { key in
                    KeyGridButton(
                        label: displayName(for: key),
                        isSelected: isCurrentKey(key),
                        isStandard: isStandardKey(key),
                        ambitus: transposedRange(for: key),
                        useFlats: true
                    ) {
                        onSelect(key)
                    }
                }
                // Treble clef indicator
                if songRange != nil {
                    Text("𝄞")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Key Grid Button

/// Individual key button with optional ambitus display
struct KeyGridButton: View {
    let label: String
    let isSelected: Bool
    let isStandard: Bool
    let ambitus: (low: Int, high: Int)?
    let useFlats: Bool
    let onTap: () -> Void

    init(label: String, isSelected: Bool, isStandard: Bool,
         ambitus: (low: Int, high: Int)? = nil, useFlats: Bool = false,
         onTap: @escaping () -> Void) {
        self.label = label
        self.isSelected = isSelected
        self.isStandard = isStandard
        self.ambitus = ambitus
        self.useFlats = useFlats
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))

                if let ambitus = ambitus {
                    AmbitusView(
                        lowMidi: ambitus.low,
                        highMidi: ambitus.high,
                        clef: .treble,
                        useFlats: useFlats
                    )
                    .frame(height: 40)
                }
            }
            .frame(width: ambitus != nil ? 52 : 44, height: ambitus != nil ? 68 : 44)
            .background(isSelected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary, lineWidth: isStandard ? 2.5 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Key Picker Sheet

/// Bottom sheet presentation for the key picker
struct KeyPickerSheet: View {
    let currentKey: String
    let standardKey: String
    let songRange: (low: Int, high: Int)?
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    init(currentKey: String, standardKey: String, songRange: (low: Int, high: Int)? = nil,
         onConfirm: @escaping (String) -> Void) {
        self.currentKey = currentKey
        self.standardKey = standardKey
        self.songRange = songRange
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color(.tertiaryLabel))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            Text("Transpose")
                .font(.headline)

            if songRange != nil {
                Text("Range shown for each key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            KeyPickerGrid(
                currentKey: currentKey,
                standardKey: standardKey,
                songRange: songRange
            ) { key in
                onConfirm(key)
                dismiss()
            }

            Spacer()
        }
        .presentationDetents([.height(songRange != nil ? 240 : 200)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Previews

#Preview("With Ambitus") {
    VStack {
        KeyPickerGrid(
            currentKey: "g",
            standardKey: "c",
            songRange: (low: 60, high: 79)  // C4 to G5
        ) { key in
            print("Selected: \(key)")
        }
    }
    .padding()
}

#Preview("Without Ambitus") {
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

#Preview("Sheet with Ambitus") {
    Text("Tap to open")
        .sheet(isPresented: .constant(true)) {
            KeyPickerSheet(
                currentKey: "c",
                standardKey: "c",
                songRange: (low: 62, high: 81)  // D4 to A5
            ) { key in
                print("Confirmed: \(key)")
            }
        }
}
