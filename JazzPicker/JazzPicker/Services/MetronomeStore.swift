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

    // Current song for per-song settings
    private(set) var currentSongTitle: String?

    // User's custom settings for current song (if any)
    @Published private(set) var userSettings: SongMetronomeSettings?

    // MARK: - Public API

    /// Load tempo from a song. Call when opening a new song in PDF viewer.
    /// Pass userProfileStore to load user's custom settings for this song.
    func loadFromSong(_ song: Song, userProfileStore: UserProfileStore? = nil) {
        print("🎵 MetronomeStore.loadFromSong(\(song.title)) - bpm: \(song.tempoBpm ?? -1), style: \(song.tempoStyle ?? "nil"), timeSig: \(song.timeSignature ?? "nil")")

        currentSongTitle = song.title
        songTempoBpm = song.tempoBpm
        songTempoStyle = song.tempoStyle
        songTimeSignature = song.timeSignature

        // Load user's custom settings for this song
        userSettings = userProfileStore?.getMetronomeSettings(for: song.title)

        // Apply settings: user override > song default
        if let userBpm = userSettings?.bpm {
            engine.bpm = userBpm
        } else if let bpm = song.tempoBpm {
            engine.bpm = bpm
        }

        // Time signature: user override > song default > 4/4
        if let userTimeSig = userSettings?.timeSignature {
            engine.setTimeSignature(userTimeSig)
        } else {
            let timeSig = song.timeSignature ?? "4/4"
            engine.setTimeSignature(timeSig)
        }

        print("🎵 loadFromSong complete - bpm: \(engine.bpm), beats: \(engine.beatsPerMeasure), hasUserSettings: \(userSettings != nil)")
    }

    /// Reset to the loaded song's default tempo (catalog values)
    func resetToSongDefaults() {
        userSettings = nil

        if let bpm = songTempoBpm {
            engine.bpm = bpm
        }
        if let timeSig = songTimeSignature {
            engine.setTimeSignature(timeSig)
        } else {
            engine.setTimeSignature("4/4")
        }
    }

    /// Save current settings as user override for this song
    func saveUserSettings(userProfileStore: UserProfileStore, uid: String) async {
        guard let songTitle = currentSongTitle else { return }

        let settings = SongMetronomeSettings(
            bpm: engine.bpm,
            timeSignature: currentTimeSignatureString
        )

        await userProfileStore.setMetronomeSettings(
            settings,
            for: songTitle,
            defaultBpm: songTempoBpm,
            defaultTimeSignature: songTimeSignature,
            uid: uid
        )

        userSettings = settings
    }

    /// Clear user settings for current song (revert to defaults)
    func clearUserSettings(userProfileStore: UserProfileStore, uid: String) async {
        guard let songTitle = currentSongTitle else { return }

        await userProfileStore.clearMetronomeSettings(for: songTitle, uid: uid)
        userSettings = nil
        resetToSongDefaults()
    }

    /// Check if user has custom settings that differ from song defaults
    var hasCustomSettings: Bool {
        userSettings != nil
    }

    /// Check if current settings differ from song defaults
    var hasDifferentSettings: Bool {
        let bpmDiffers = songTempoBpm != nil && engine.bpm != songTempoBpm
        let timeSigDiffers = songTimeSignature != nil && currentTimeSignatureString != songTimeSignature
        return bpmDiffers || timeSigDiffers
    }

    /// Current time signature as string (e.g., "4/4")
    var currentTimeSignatureString: String {
        "\(engine.beatsPerMeasure)/\(engine.noteValue)"
    }

    /// Legacy compatibility
    var hasDifferentTempo: Bool {
        hasDifferentSettings
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
