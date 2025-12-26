#!/usr/bin/env python3
"""
MusicXML to LilyPond multi-part converter.
Extracts all parts from MusicXML and generates Core + Wrapper files.

Usage:
    python musicxml_to_lilypond.py <xml_file> [--analyze] [--compile]
"""

import argparse
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from music21 import converter, key, meter, tempo


def analyze_xml(xml_path: str) -> dict:
    """Load MusicXML and return analysis info."""
    score = converter.parse(xml_path)

    # Get title from score metadata or filename
    title = Path(xml_path).stem
    if score.metadata and score.metadata.title:
        title = score.metadata.title

    # Get composer
    composer = ""
    if score.metadata and score.metadata.composer:
        composer = score.metadata.composer

    info = {
        "path": xml_path,
        "title": title,
        "composer": composer,
        "parts": [],
        "key_signature": None,
        "analyzed_key": None,
        "tempo": None,
        "time_signature": "4/4",
    }

    # Key signature from first part
    for part in score.parts:
        ks = part.flatten().getElementsByClass("KeySignature")
        if ks:
            info["key_signature"] = ks[0]
            break

    # Analyze key
    try:
        info["analyzed_key"] = score.analyze("key")
    except:
        pass

    # Tempo
    tempos = score.flatten().getElementsByClass(tempo.MetronomeMark)
    if tempos:
        info["tempo"] = int(tempos[0].number)

    # Time signature
    ts = score.flatten().getElementsByClass(meter.TimeSignature)
    if ts:
        info["time_signature"] = ts[0].ratioString

    # Analyze each part
    for i, part in enumerate(score.parts):
        # Get part name from MusicXML
        part_name = f"Part {i+1}"
        if hasattr(part, 'partName') and part.partName:
            part_name = part.partName
        elif part.id:
            # Try to get from part-list in original XML
            pass

        inst = part.getInstrument()
        if inst and inst.instrumentName:
            part_name = inst.instrumentName

        notes = part.flatten().notes
        measures = part.getElementsByClass('Measure')
        part_info = {
            "index": i,
            "name": part_name,
            "note_count": len(notes),
            "measure_count": len(measures),
            "low": None,
            "high": None,
        }

        if notes:
            pitches = []
            for n in notes:
                if hasattr(n, "pitch"):
                    pitches.append(n.pitch)
                elif hasattr(n, "pitches") and n.pitches:
                    pitches.extend(n.pitches)

            if pitches:
                part_info["low"] = min(pitches, key=lambda p: p.midi)
                part_info["high"] = max(pitches, key=lambda p: p.midi)

        info["parts"].append(part_info)

    # Sanity check: all parts should have the same number of measures
    if info["parts"]:
        measure_counts = [p["measure_count"] for p in info["parts"]]
        if len(set(measure_counts)) > 1:
            print(f"WARNING: Parts have different measure counts: {measure_counts}")

    return info


def print_analysis(info: dict):
    """Pretty-print MusicXML analysis."""
    print(f"\n=== {info['title']} ===")
    if info['composer']:
        print(f"Composer: {info['composer']}")
    print(f"Parts: {len(info['parts'])}")

    for p in info["parts"]:
        if p["low"] and p["high"]:
            range_str = f"{p['low'].nameWithOctave}-{p['high'].nameWithOctave}"
        else:
            range_str = "empty"
        print(f"  [{p['index']}] {p['name']}: {p['note_count']} notes, {range_str}")

    if info["analyzed_key"]:
        print(f"Key: {info['analyzed_key']}")
    if info["tempo"]:
        print(f"Tempo: {info['tempo']} BPM")
    print(f"Time: {info['time_signature']}")


def suggest_clef(low_pitch, high_pitch) -> str:
    """Suggest appropriate clef based on pitch range."""
    if low_pitch is None:
        return "treble"

    avg_midi = (low_pitch.midi + high_pitch.midi) / 2

    if avg_midi < 55:  # Below G3
        return "bass"
    else:
        return "treble"


def _key_to_lilypond_pitch(key_obj) -> str:
    """Convert music21 key tonic to LilyPond pitch using English names (for refrainKey)."""
    name = key_obj.tonic.name.lower()
    # Convert accidentals to English names (bf, ef, etc.)
    name = name.replace("-", "f").replace("#", "s")
    return name


def _key_to_display(key_obj) -> str:
    """Convert key to display name like 'Bb' or 'F#'."""
    name = key_obj.tonic.name
    name = name.replace("-", "b").replace("#", "#")
    return name


class RelativePitchTracker:
    """Track previous pitch for relative notation output."""

    def __init__(self, reference_midi=65):  # F4 for \relative f'
        self.prev_midi = reference_midi
        self.prev_octave = 4

    def convert(self, pitch) -> str:
        """Convert pitch to LilyPond relative notation using English names."""
        name = pitch.step.lower()

        # Accidentals using English names (bf, ef, fs, cs, etc.)
        if pitch.accidental:
            acc = pitch.accidental.name
            if acc == "sharp":
                name += "s"
            elif acc == "flat":
                name += "f"
            elif acc == "double-sharp":
                name += "ss"
            elif acc == "double-flat":
                name += "ff"

        # Calculate octave markers based on relative pitch
        # LilyPond relative mode: pick the closest pitch, add ' or , for octave jumps
        target_midi = pitch.midi
        target_octave = pitch.octave

        # How many octaves apart are we from the expected position?
        # In relative mode, LilyPond picks the note within a fourth
        # So we need to figure out what octave LilyPond would pick, then adjust

        # Get the pitch class (0-11) of previous and current
        prev_pc = self.prev_midi % 12
        curr_pc = target_midi % 12

        # Calculate the interval in the same octave
        interval = curr_pc - prev_pc
        if interval > 6:
            interval -= 12  # Pick the closer direction
        elif interval < -6:
            interval += 12

        # What MIDI note would LilyPond pick (closest within a fourth)?
        expected_midi = self.prev_midi + interval

        # How many octaves off is the actual note?
        octave_diff = (target_midi - expected_midi) // 12

        if octave_diff > 0:
            name += "'" * octave_diff
        elif octave_diff < 0:
            name += "," * (-octave_diff)

        # Update tracker
        self.prev_midi = target_midi
        self.prev_octave = target_octave

        return name


def _duration_to_lilypond(quarter_length: float) -> tuple:
    """Convert quarter length to LilyPond duration string and actual quarter length used."""
    simple_map = {
        4.0: "1", 3.0: "2.", 2.0: "2", 1.5: "4.", 1.0: "4",
        0.75: "8.", 0.5: "8", 0.375: "16.", 0.25: "16",
        0.125: "32", 0.0625: "64",
    }

    for ql, dur_str in simple_map.items():
        if abs(quarter_length - ql) < 0.01:
            return dur_str, ql

    # Compound durations that need ties
    compound_map = {
        3.5: ("2.~ ", 3.0, "8", 0.5),
        2.5: ("2~ ", 2.0, "8", 0.5),
        1.25: ("4~ ", 1.0, "16", 0.25),
    }

    for ql, (first, first_ql, second, second_ql) in compound_map.items():
        if abs(quarter_length - ql) < 0.01:
            return f"{first}{{TIE}}{second}", ql

    # Fallback
    for ql in sorted(simple_map.keys(), reverse=True):
        if quarter_length >= ql - 0.01:
            return simple_map[ql], ql

    return "16", 0.25


def _fill_measure(current_beats: float, beats_per_measure: float) -> list:
    """Generate rests to fill remaining beats in a measure."""
    remaining = beats_per_measure - current_beats
    rests = []

    rest_values = [(2.0, "r2"), (1.0, "r4"), (0.5, "r8"), (0.25, "r16")]

    while remaining > 0.01:
        for ql, rest_str in rest_values:
            if remaining >= ql - 0.01:
                rests.append(rest_str)
                remaining -= ql
                break
        else:
            break

    return rests


def _extract_repeat_structure(xml_path: str) -> list:
    """
    Extract measure playback order from MusicXML repeat structure.

    Returns list of original measure numbers in playback order.
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    parts = root.findall('.//part')
    if not parts:
        return []

    part = parts[0]
    measures = part.findall('measure')

    # Build repeat structure
    repeat_start = None
    first_ending_start = None
    first_ending_end = None
    playback_order = []
    current_ending = None

    for m in measures:
        m_num = int(m.get('number', 0))

        # Check for repeat signs and endings
        for barline in m.findall('barline'):
            repeat = barline.find('repeat')
            ending = barline.find('ending')

            if repeat is not None:
                direction = repeat.get('direction')
                if direction == 'forward':
                    repeat_start = m_num
                elif direction == 'backward':
                    # End of repeated section
                    if current_ending == '1':
                        first_ending_end = m_num

            if ending is not None:
                ending_type = ending.get('type')
                ending_number = ending.get('number', '1')
                if ending_type == 'start':
                    current_ending = ending_number
                    if ending_number == '1':
                        first_ending_start = m_num
                elif ending_type in ('stop', 'discontinue'):
                    current_ending = None

    # Build list of all measure numbers
    all_measures = [int(m.get('number', 0)) for m in measures]

    # If we have a repeat structure with endings, expand it
    if repeat_start is not None and first_ending_start is not None and first_ending_end is not None:
        # Structure:
        # - First time: play from start through first ending
        # - Second time: repeat section, skip first ending, play second ending

        second_ending_start = first_ending_end + 1

        expanded = []

        # First time through: pickup + repeated section + first ending
        for m_num in all_measures:
            if m_num <= first_ending_end:
                expanded.append(m_num)

        # Second time: repeated section (skip pickup and first ending) + second ending
        for m_num in all_measures:
            if repeat_start <= m_num < first_ending_start:
                expanded.append(m_num)

        # Add second ending
        for m_num in all_measures:
            if m_num >= second_ending_start:
                expanded.append(m_num)

        return expanded

    return all_measures


def _extract_harmonies_from_xml(xml_path: str, part_id: str = None, expand_repeats: bool = False) -> list:
    """
    Extract harmony elements directly from MusicXML.

    Returns list of dicts: {measure_num, beat_offset, root, alter, kind}
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    harmonies = []

    # Find all parts
    parts = root.findall('.//part')

    # If part_id specified, only look at that part; otherwise use first part with harmonies
    target_part = None
    for part in parts:
        if part_id and part.get('id') == part_id:
            target_part = part
            break
        # Check if this part has harmonies
        if part.findall('.//harmony'):
            target_part = part
            break

    if target_part is None:
        return []

    # Get divisions (ticks per quarter note) - may change per measure
    divisions = 1

    for measure in target_part.findall('measure'):
        measure_num = int(measure.get('number', 0))

        # Check for divisions update
        attrs = measure.find('attributes')
        if attrs is not None:
            div_elem = attrs.find('divisions')
            if div_elem is not None:
                divisions = int(div_elem.text)

        # Track position within measure
        current_offset = 0.0

        for elem in measure:
            if elem.tag == 'harmony':
                root_step = elem.find('.//root-step')
                root_alter = elem.find('.//root-alter')

                # Get the non-empty kind element
                kind_text = "major"  # default
                for kind_elem in elem.findall('kind'):
                    if kind_elem.text:
                        kind_text = kind_elem.text
                        break

                root_name = root_step.text if root_step is not None else "C"
                alter = int(root_alter.text) if root_alter is not None else 0

                harmonies.append({
                    'measure': measure_num,
                    'beat': current_offset,
                    'root': root_name,
                    'alter': alter,
                    'kind': kind_text,
                })

            elif elem.tag == 'note':
                # Advance position (but not for chord notes)
                chord = elem.find('chord')
                if chord is None:
                    duration = elem.find('duration')
                    if duration is not None:
                        # Convert duration ticks to quarter notes
                        current_offset += int(duration.text) / divisions

            elif elem.tag == 'forward':
                duration = elem.find('duration')
                if duration is not None:
                    current_offset += int(duration.text) / divisions

            elif elem.tag == 'backup':
                duration = elem.find('duration')
                if duration is not None:
                    current_offset -= int(duration.text) / divisions

    # Optionally expand harmonies according to repeat structure
    if expand_repeats:
        playback_order = _extract_repeat_structure(xml_path)
        if playback_order:
            # Build a map of original measure -> harmonies in that measure
            harmonies_by_measure = {}
            for h in harmonies:
                m = h['measure']
                if m not in harmonies_by_measure:
                    harmonies_by_measure[m] = []
                harmonies_by_measure[m].append(h)

            # Expand harmonies following playback order
            expanded_harmonies = []
            new_measure_num = 0
            for orig_measure in playback_order:
                new_measure_num += 1
                if orig_measure in harmonies_by_measure:
                    for h in harmonies_by_measure[orig_measure]:
                        expanded_harmonies.append({
                            'measure': new_measure_num,
                            'beat': h['beat'],
                            'root': h['root'],
                            'alter': h['alter'],
                            'kind': h['kind'],
                        })

            return expanded_harmonies

    return harmonies


def _harmony_to_lilypond(harmony: dict, duration: str = "") -> str:
    """Convert a harmony dict to LilyPond chordmode notation.

    In LilyPond chordmode, duration comes after root: c1:maj7 (C major 7, whole note)
    """
    # Map root + alter to LilyPond pitch
    root = harmony['root'].lower()
    alter = harmony['alter']

    if alter == -1:
        root += 'f'  # flat
    elif alter == 1:
        root += 's'  # sharp
    elif alter == -2:
        root += 'ff'
    elif alter == 2:
        root += 'ss'

    # Map MusicXML kind to LilyPond chord suffix
    kind_map = {
        'major': '',
        'minor': ':m',
        'dominant': ':7',
        'major-seventh': ':maj7',
        'minor-seventh': ':m7',
        'diminished': ':dim',
        'augmented': ':aug',
        'half-diminished': ':m7.5-',
        'diminished-seventh': ':dim7',
        'major-minor': ':m.maj7',
        'major-sixth': ':6',
        'minor-sixth': ':m6',
        'dominant-ninth': ':9',
        'major-ninth': ':maj9',
        'minor-ninth': ':m9',
        'dominant-11th': ':11',
        'major-11th': ':maj11',
        'minor-11th': ':m11',
        'dominant-13th': ':13',
        'major-13th': ':maj13',
        'minor-13th': ':m13',
        'suspended-second': ':sus2',
        'suspended-fourth': ':sus4',
        'power': ':1.5',
    }

    suffix = kind_map.get(harmony['kind'], '')

    # Format: root + duration + suffix (e.g., bf1:7 for Bb dominant 7, whole note)
    return f"{root}{duration}{suffix}"


def _harmonies_to_chordmode(harmonies: list, beats_per_measure: int = 4) -> str:
    """
    Convert list of harmonies to LilyPond chordmode string.
    Groups by measure with bar checks.
    """
    if not harmonies:
        return ""

    # Group harmonies by measure
    measures = {}
    for h in harmonies:
        m = h['measure']
        if m not in measures:
            measures[m] = []
        measures[m].append(h)

    # Build chordmode content
    lines = []
    current_measure = []

    for measure_num in sorted(measures.keys()):
        measure_harmonies = sorted(measures[measure_num], key=lambda x: x['beat'])
        measure_content = []

        for i, h in enumerate(measure_harmonies):
            # Calculate duration to next chord or end of measure
            if i + 1 < len(measure_harmonies):
                next_beat = measure_harmonies[i + 1]['beat']
            else:
                next_beat = beats_per_measure

            duration_beats = next_beat - h['beat']

            # Convert beats to LilyPond duration
            if abs(duration_beats - beats_per_measure) < 0.01:
                dur_str = "1"
            elif abs(duration_beats - beats_per_measure / 2) < 0.01:
                dur_str = "2"
            elif abs(duration_beats - beats_per_measure / 4) < 0.01:
                dur_str = "4"
            elif abs(duration_beats - beats_per_measure * 3 / 4) < 0.01:
                dur_str = "2."
            else:
                # Default to quarter note for complex durations
                dur_str = "4"

            chord_str = _harmony_to_lilypond(h, dur_str)
            measure_content.append(chord_str)

        current_measure.append(" ".join(measure_content))

        # Add bar line every measure, line break every 4 measures
        if len(current_measure) == 4:
            lines.append(" | ".join(current_measure))
            current_measure = []

    # Add remaining measures
    if current_measure:
        lines.append(" | ".join(current_measure))

    return "\n  ".join(lines)


def _detect_pickup(notes_and_rests, beats_per_measure=4) -> float:
    """Detect if song starts with a pickup (anacrusis)."""
    rest_beats = 0.0
    for element in notes_and_rests:
        if element.isRest:
            rest_beats += element.duration.quarterLength
        else:
            break

    if 0 < rest_beats < beats_per_measure:
        pickup_beats = beats_per_measure - rest_beats
        return pickup_beats

    return 0.0


def _notes_to_lilypond_measures(part, beats_per_measure=4) -> tuple:
    """Convert notes to LilyPond relative notation, grouped by measure."""
    notes_and_rests = list(part.flatten().notesAndRests)

    pickup_beats = _detect_pickup(notes_and_rests, beats_per_measure)

    measures = []
    current_measure = []
    current_beats = 0.0
    tracker = RelativePitchTracker(reference_midi=65)  # F4 for \relative f'

    start_idx = 0
    if pickup_beats > 0:
        rest_beats = 0.0
        for i, element in enumerate(notes_and_rests):
            if element.isRest:
                rest_beats += element.duration.quarterLength
            else:
                start_idx = i
                break
        current_beats = beats_per_measure - pickup_beats

    for element in notes_and_rests[start_idx:]:
        ql = element.duration.quarterLength

        # Skip zero-duration elements (grace notes, articulation markers)
        if ql < 0.01:
            continue

        dur_str, actual_ql = _duration_to_lilypond(ql)

        if current_beats + actual_ql > beats_per_measure + 0.01:
            if current_beats < beats_per_measure - 0.01:
                current_measure.extend(_fill_measure(current_beats, beats_per_measure))
            if current_measure:
                measures.append(current_measure)
            current_measure = []
            current_beats = 0.0

        if element.isRest:
            # Rests don't affect pitch tracking
            if "{TIE}" in dur_str:
                parts = dur_str.split("{TIE}")
                note_str = f"r{parts[0].rstrip('~ ')} r{parts[1]}"
            else:
                note_str = f"r{dur_str}"
        elif hasattr(element, "pitch"):
            # Single note
            pitch_str = tracker.convert(element.pitch)

            if "{TIE}" in dur_str:
                parts = dur_str.split("{TIE}")
                # For tied notes, strip octave markers for second note
                base_pitch = pitch_str.replace("'", "").replace(",", "")
                note_str = f"{pitch_str}{parts[0]}{base_pitch}{parts[1]}"
            else:
                note_str = f"{pitch_str}{dur_str}"
        elif hasattr(element, "pitches") and element.pitches:
            # Chord - handle as single note if only one pitch
            if len(element.pitches) == 1:
                pitch_str = tracker.convert(element.pitches[0])
                if "{TIE}" in dur_str:
                    parts = dur_str.split("{TIE}")
                    base_pitch = pitch_str.replace("'", "").replace(",", "")
                    note_str = f"{pitch_str}{parts[0]}{base_pitch}{parts[1]}"
                else:
                    note_str = f"{pitch_str}{dur_str}"
            else:
                # Actual chord with multiple pitches
                # In relative mode, first note is relative to previous pitch,
                # subsequent notes are relative to previous note in chord
                chord_strs = []
                for j, p in enumerate(element.pitches):
                    chord_strs.append(tracker.convert(p))
                # Update tracker with first note of chord for next element
                tracker.prev_midi = element.pitches[0].midi
                pitches_str = " ".join(chord_strs)
                if "{TIE}" in dur_str:
                    parts = dur_str.split("{TIE}")
                    note_str = f"<{pitches_str}>{parts[0]}<{pitches_str}>{parts[1]}"
                else:
                    note_str = f"<{pitches_str}>{dur_str}"
        else:
            continue

        current_measure.append(note_str)
        current_beats += actual_ql

        if abs(current_beats - beats_per_measure) < 0.01:
            measures.append(current_measure)
            current_measure = []
            current_beats = 0.0

    if current_measure:
        expected_last = beats_per_measure - pickup_beats if pickup_beats > 0 else beats_per_measure
        if current_beats < expected_last - 0.01:
            current_measure.extend(_fill_measure(current_beats, expected_last))
        measures.append(current_measure)

    return measures, pickup_beats


def generate_core_file(part, info: dict, part_name: str, clef_name: str = None, xml_path: str = None) -> str:
    """Generate LilyPond Core file in lilypond-lead-sheets style."""

    title = info["title"]
    composer = info["composer"] or ""
    key_obj = info["analyzed_key"] or key.Key("C")
    tempo_bpm = info["tempo"] or 120
    time_sig = info["time_signature"] or "4/4"

    # Determine clef from part range
    if clef_name is None:
        part_info = next((p for p in info["parts"] if p["name"] == part_name), None)
        if part_info and part_info.get("low") and part_info.get("high"):
            clef_name = suggest_clef(part_info["low"], part_info["high"])
        else:
            clef_name = "treble"

    # Parse time signature
    if "/" in time_sig:
        beats = int(time_sig.split("/")[0])
    else:
        beats = 4

    measures, pickup_beats = _notes_to_lilypond_measures(part, beats)

    # Extract chord symbols from XML (with repeat expansion)
    chords_content = ""
    if xml_path:
        harmonies = _extract_harmonies_from_xml(xml_path, expand_repeats=True)
        if harmonies:
            chords_content = _harmonies_to_chordmode(harmonies, beats)

    # Build melody with bar lines
    melody_lines = []
    for i, measure in enumerate(measures):
        measure_str = " ".join(measure)
        if i < len(measures) - 1:
            measure_str += " |"
        melody_lines.append(measure_str)

        # Add line breaks every 4 measures
        if i < len(measures) - 1:
            if pickup_beats > 0:
                if i == 4 or (i > 4 and (i - 4) % 4 == 0):
                    melody_lines.append("\\break")
            else:
                if (i + 1) % 4 == 0:
                    melody_lines.append("\\break")

    melody_content = "\n  ".join(melody_lines)

    # Partial for pickup
    partial_cmd = ""
    if pickup_beats > 0:
        if pickup_beats == 2:
            partial_cmd = "\\partial 2\n  "
        elif pickup_beats == 1:
            partial_cmd = "\\partial 4\n  "
        elif pickup_beats == 3:
            partial_cmd = "\\partial 2.\n  "
        elif pickup_beats == 0.5:
            partial_cmd = "\\partial 8\n  "

    refrain_key = _key_to_lilypond_pitch(key_obj)

    # Tempo text
    tempo_text = "Medium Swing"
    if tempo_bpm > 160:
        tempo_text = "Up Tempo"
    elif tempo_bpm > 140:
        tempo_text = "Bright Swing"
    elif tempo_bpm < 80:
        tempo_text = "Ballad"
    elif tempo_bpm < 100:
        tempo_text = "Slow Swing"

    # Build refrainChords section if we have chords
    chords_section = ""
    if chords_content:
        chords_section = f'''
refrainChords = \\chordmode {{
  {chords_content}
}}
'''

    # Generate Core content
    # For multi-part scores, subtitle shows just the part name
    ly_content = f'''%% -*- Mode: LilyPond -*-

\\include "../../lilypond-data/Include/lead-sheets.ily"

\\header {{
  title = "{title}"
  subtitle = "{part_name}"
  poet = ""
  composer = "{composer}"
  copyright = \\markup \\small {{ \\now " " }}
}}

refrainKey = {refrain_key}
{chords_section}
refrainMelody = \\relative f' {{
  \\time {time_sig}
  \\key \\refrainKey \\{"major" if key_obj.mode == "major" else "minor"}
  \\clef \\whatClef
  \\tempo "{tempo_text}" 4 = {tempo_bpm}

  {partial_cmd}{melody_content}

  \\bar "|."
}}

\\include "../../lilypond-data/Include/paper.ily"

\\markup {{
  % Leave a gap after the header
  \\vspace #1
}}

\\include "../../lilypond-data/Include/refrain.ily"
'''
    return ly_content


def generate_wrapper_file(core_filename: str, key_obj, clef: str = "treble") -> str:
    """Generate LilyPond Wrapper file."""
    key_lily = _key_to_lilypond_pitch(key_obj)

    return f'''\\version "2.24.0"

\\include "english.ly"

instrument = "Standard Key"
whatKey = {key_lily}
whatClef = "{clef}"

\\include "../Core/{core_filename}"
'''


def sanitize_part_name(name: str) -> str:
    """Clean up part name for use in filenames."""
    # Handle duplicate violin names
    name = name.strip()
    # Remove problematic characters
    name = name.replace("/", "-").replace("\\", "-")
    return name


def extract_all_parts(xml_path: str, output_dir: str = None, compile_pdf: bool = False):
    """Extract all parts from MusicXML and generate Core + Wrapper files."""

    info = analyze_xml(xml_path)
    print_analysis(info)

    if output_dir is None:
        # Default to custom-charts directory
        script_dir = Path(__file__).parent.parent
        output_dir = script_dir

    output_dir = Path(output_dir)
    core_dir = output_dir / "custom-charts" / "Core"
    wrapper_dir = output_dir / "custom-charts" / "Wrappers"

    core_dir.mkdir(parents=True, exist_ok=True)
    wrapper_dir.mkdir(parents=True, exist_ok=True)

    title = info["title"]
    key_obj = info["analyzed_key"] or key.Key("C")
    key_display = _key_to_display(key_obj)

    score = converter.parse(xml_path)

    # Expand repeats to get full chart
    score = score.expandRepeats()

    # Track violin numbering
    part_name_counts = {}

    generated_files = []

    for i, part in enumerate(score.parts):
        part_info = info["parts"][i]
        part_name = sanitize_part_name(part_info["name"])

        # Handle duplicate part names (e.g., two Violins)
        if part_name in part_name_counts:
            part_name_counts[part_name] += 1
            part_name = f"{part_name} {part_name_counts[part_name]}"
        else:
            part_name_counts[part_name] = 1

        print(f"\nProcessing: {part_name}")

        # Determine clef based on pitch range
        clef = "treble"
        if part_info.get("low") and part_info.get("high"):
            clef = suggest_clef(part_info["low"], part_info["high"])

        # Generate Core file
        core_content = generate_core_file(part, info, part_name, xml_path=xml_path)
        core_filename = f"{title} - Ly Core - {part_name} - {key_display}.ly"
        core_path = core_dir / core_filename

        with open(core_path, "w") as f:
            f.write(core_content)
        print(f"  Core: {core_path.name}")

        # Generate Wrapper file
        wrapper_content = generate_wrapper_file(core_filename, key_obj, clef)
        wrapper_filename = f"{title} ({part_name}) - Ly - {key_display} Standard.ly"
        wrapper_path = wrapper_dir / wrapper_filename

        with open(wrapper_path, "w") as f:
            f.write(wrapper_content)
        print(f"  Wrapper: {wrapper_path.name}")

        generated_files.append({
            "part_name": part_name,
            "core_path": core_path,
            "wrapper_path": wrapper_path,
        })

        # Optionally compile to PDF
        if compile_pdf:
            compile_lilypond(wrapper_path)

    return generated_files


def compile_lilypond(ly_path: Path) -> str:
    """Compile LilyPond file to PDF."""
    output_dir = ly_path.parent

    result = subprocess.run(
        ["lilypond", "-o", str(output_dir / ly_path.stem), str(ly_path)],
        capture_output=True,
        text=True,
        cwd=output_dir
    )

    pdf_path = output_dir / f"{ly_path.stem}.pdf"
    if pdf_path.exists():
        print(f"  Compiled: {pdf_path.name}")
        return str(pdf_path)
    else:
        print(f"  Compilation failed:")
        print(result.stderr[-300:] if len(result.stderr) > 300 else result.stderr)
        return None


def main():
    parser = argparse.ArgumentParser(description="MusicXML to LilyPond multi-part converter")
    parser.add_argument("xml_file", help="Input MusicXML file")
    parser.add_argument("--analyze", "-a", action="store_true",
                        help="Only analyze, don't generate files")
    parser.add_argument("--compile", "-c", action="store_true",
                        help="Compile to PDF after export")
    parser.add_argument("--output", "-o", type=str, default=None,
                        help="Output directory (default: project root)")

    args = parser.parse_args()

    if args.analyze:
        info = analyze_xml(args.xml_file)
        print_analysis(info)
    else:
        extract_all_parts(args.xml_file, args.output, args.compile)


if __name__ == "__main__":
    main()
