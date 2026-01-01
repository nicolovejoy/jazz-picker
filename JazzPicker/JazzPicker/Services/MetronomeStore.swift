//
//  MetronomeStore.swift
//  JazzPicker
//
//  Session-level metronome state management.
//

import SwiftUI
import Combine

@MainActor
class MetronomeStore: ObservableObject {
    // MARK: - Published State

    let engine = MetronomeEngine()
    @Published var isVisible = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Forward engine changes to trigger view updates
        engine.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    // Song tempo info for "reset to song tempo" feature
    @Published private(set) var songTempoBpm: Int?
    @Published private(set) var songTempoStyle: String?
    @Published private(set) var songTimeSignature: String?

    // MARK: - Public API

    /// Load tempo from a song. Call when opening a new song in PDF viewer.
    func loadFromSong(_ song: Song) {
        print("🎵 MetronomeStore.loadFromSong(\(song.title)) - bpm: \(song.tempoBpm ?? -1), style: \(song.tempoStyle ?? "nil"), timeSig: \(song.timeSignature ?? "nil")")
        songTempoBpm = song.tempoBpm
        songTempoStyle = song.tempoStyle
        songTimeSignature = song.timeSignature

        // Set engine tempo if song has one, otherwise keep current
        if let bpm = song.tempoBpm {
            engine.bpm = bpm
        }

        // Set time signature - reset to 4/4 if song doesn't specify
        let timeSig = song.timeSignature ?? "4/4"
        engine.setTimeSignature(timeSig)
        print("🎵 loadFromSong complete - bpm: \(engine.bpm), beats: \(engine.beatsPerMeasure)")
    }

    /// Reset to the loaded song's tempo
    func resetToSongTempo() {
        if let bpm = songTempoBpm {
            engine.bpm = bpm
        }
        if let timeSig = songTimeSignature {
            engine.setTimeSignature(timeSig)
        }
    }

    /// Check if current tempo differs from song tempo
    var hasDifferentTempo: Bool {
        guard let songBpm = songTempoBpm else { return false }
        return engine.bpm != songBpm
    }

    /// Show the metronome overlay
    func show() {
        print("🎵 MetronomeStore.show() called, setting isVisible = true")
        isVisible = true
        print("🎵 MetronomeStore.isVisible is now: \(isVisible)")
    }

    /// Hide the metronome overlay (keeps playing if already playing)
    func hide() {
        isVisible = false
    }

    /// Toggle overlay visibility
    func toggle() {
        isVisible.toggle()
    }
}
