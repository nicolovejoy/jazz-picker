/**
 * Renders a musical staff showing the note range (ambitus) for a song.
 * Uses Canvas-like rendering via SVG to draw staff lines and note heads.
 */

interface AmbitusViewProps {
  lowMidi: number;
  highMidi: number;
  useFlats?: boolean;
}

// Maps pitch class (0-11) to staff position and accidental for sharp keys
const pitchClassToSharp: Array<{ diatonic: number; accidental: 'natural' | 'sharp' | 'flat' }> = [
  { diatonic: 0, accidental: 'natural' },  // C
  { diatonic: 0, accidental: 'sharp' },    // C#
  { diatonic: 1, accidental: 'natural' },  // D
  { diatonic: 1, accidental: 'sharp' },    // D#
  { diatonic: 2, accidental: 'natural' },  // E
  { diatonic: 3, accidental: 'natural' },  // F
  { diatonic: 3, accidental: 'sharp' },    // F#
  { diatonic: 4, accidental: 'natural' },  // G
  { diatonic: 4, accidental: 'sharp' },    // G#
  { diatonic: 5, accidental: 'natural' },  // A
  { diatonic: 5, accidental: 'sharp' },    // A#
  { diatonic: 6, accidental: 'natural' },  // B
];

// Maps pitch class for flat keys
const pitchClassToFlat: Array<{ diatonic: number; accidental: 'natural' | 'sharp' | 'flat' }> = [
  { diatonic: 0, accidental: 'natural' },  // C
  { diatonic: 1, accidental: 'flat' },     // Db
  { diatonic: 1, accidental: 'natural' },  // D
  { diatonic: 2, accidental: 'flat' },     // Eb
  { diatonic: 2, accidental: 'natural' },  // E
  { diatonic: 3, accidental: 'natural' },  // F
  { diatonic: 4, accidental: 'flat' },     // Gb
  { diatonic: 4, accidental: 'natural' },  // G
  { diatonic: 5, accidental: 'flat' },     // Ab
  { diatonic: 5, accidental: 'natural' },  // A
  { diatonic: 6, accidental: 'flat' },     // Bb
  { diatonic: 6, accidental: 'natural' },  // B
];

function midiToStaffNote(midi: number, useFlats: boolean) {
  const octave = Math.floor(midi / 12) - 1;
  const pitchClass = midi % 12;

  const mapping = useFlats ? pitchClassToFlat : pitchClassToSharp;
  const { diatonic, accidental } = mapping[pitchClass];

  // Diatonic position: 0 = C0, 7 = C1, etc.
  const diatonicPosition = octave * 7 + diatonic;

  return { diatonicPosition, accidental };
}

// Bottom line of treble clef staff is E4 (MIDI 64, diatonic 30)
const BOTTOM_LINE_DIATONIC = 30;

export function AmbitusView({ lowMidi, highMidi, useFlats = false }: AmbitusViewProps) {
  const width = 52;
  const height = 40;
  const lineSpacing = 5;
  const staffHeight = lineSpacing * 4;
  const staffTop = (height - staffHeight) / 2;
  const bottomLineY = staffTop + staffHeight;
  const noteRadius = lineSpacing * 0.45;

  // Calculate note positions
  const lowNote = midiToStaffNote(lowMidi, useFlats);
  const highNote = midiToStaffNote(highMidi, useFlats);

  const lowStepsFromBottom = lowNote.diatonicPosition - BOTTOM_LINE_DIATONIC;
  const highStepsFromBottom = highNote.diatonicPosition - BOTTOM_LINE_DIATONIC;

  const lowY = bottomLineY - (lowStepsFromBottom * lineSpacing / 2);
  const highY = bottomLineY - (highStepsFromBottom * lineSpacing / 2);

  // Generate ledger lines for a note
  const getLedgerLines = (stepsFromBottom: number, x: number) => {
    const lines: number[] = [];
    const ledgerWidth = noteRadius * 3;

    // Below staff
    if (stepsFromBottom < 0) {
      let step = -2;
      while (step >= stepsFromBottom) {
        lines.push(bottomLineY - (step * lineSpacing / 2));
        step -= 2;
      }
    }

    // Above staff
    if (stepsFromBottom > 8) {
      let step = 10;
      while (step <= stepsFromBottom) {
        lines.push(bottomLineY - (step * lineSpacing / 2));
        step += 2;
      }
    }

    return lines.map((y, i) => (
      <line
        key={`ledger-${x}-${i}`}
        x1={x - ledgerWidth / 2}
        y1={y}
        x2={x + ledgerWidth / 2}
        y2={y}
        stroke="currentColor"
        strokeWidth={0.5}
      />
    ));
  };

  const lowX = width * 0.35;
  const highX = width * 0.65;

  return (
    <svg
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      className="text-gray-300"
    >
      {/* Staff lines */}
      {[0, 1, 2, 3, 4].map((i) => (
        <line
          key={`staff-${i}`}
          x1={2}
          y1={staffTop + i * lineSpacing}
          x2={width - 2}
          y2={staffTop + i * lineSpacing}
          stroke="currentColor"
          strokeWidth={0.5}
          opacity={0.5}
        />
      ))}

      {/* Ledger lines */}
      {getLedgerLines(lowStepsFromBottom, lowX)}
      {getLedgerLines(highStepsFromBottom, highX)}

      {/* Accidentals */}
      {lowNote.accidental !== 'natural' && (
        <text
          x={lowX - noteRadius * 2.5}
          y={lowY}
          fontSize={lineSpacing * 2}
          textAnchor="middle"
          dominantBaseline="central"
          fill="currentColor"
        >
          {lowNote.accidental === 'sharp' ? '♯' : '♭'}
        </text>
      )}
      {highNote.accidental !== 'natural' && (
        <text
          x={highX - noteRadius * 2.5}
          y={highY}
          fontSize={lineSpacing * 2}
          textAnchor="middle"
          dominantBaseline="central"
          fill="currentColor"
        >
          {highNote.accidental === 'sharp' ? '♯' : '♭'}
        </text>
      )}

      {/* Note heads (ellipses rotated slightly) */}
      <ellipse
        cx={lowX}
        cy={lowY}
        rx={noteRadius}
        ry={noteRadius * 0.75}
        fill="currentColor"
        transform={`rotate(-17 ${lowX} ${lowY})`}
      />
      <ellipse
        cx={highX}
        cy={highY}
        rx={noteRadius}
        ry={noteRadius * 0.75}
        fill="currentColor"
        transform={`rotate(-17 ${highX} ${highY})`}
      />
    </svg>
  );
}
