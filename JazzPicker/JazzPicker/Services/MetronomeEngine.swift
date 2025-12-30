//
//  MetronomeEngine.swift
//  JazzPicker
//
//  AVAudioEngine-based metronome with haptic feedback and tap tempo.
//

import AVFoundation
import UIKit
import Combine

@MainActor
class MetronomeEngine: ObservableObject {
    // MARK: - Published State

    @Published var isPlaying = false
    @Published private(set) var currentBeat: Int = 0  // 0-indexed
    @Published var bpm: Int = 120 {
        didSet {
            let clamped = max(30, min(400, bpm))
            if bpm != clamped {
                bpm = clamped
            }
        }
    }
    @Published var beatsPerMeasure: Int = 4

    // MARK: - Audio Engine

    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var clickBuffer: AVAudioPCMBuffer?
    private var accentBuffer: AVAudioPCMBuffer?

    // MARK: - Timing

    private var displayLink: CADisplayLink?
    private var nextBeatTime: TimeInterval = 0
    private var beatInterval: TimeInterval { 60.0 / Double(bpm) }

    // MARK: - Haptics

    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)

    // MARK: - Tap Tempo

    private var tapTimes: [Date] = []
    private let maxTapInterval: TimeInterval = 2.0
    private let tapHistoryCount = 4

    // MARK: - Initialization

    init() {
        impactGenerator.prepare()
        heavyImpactGenerator.prepare()
    }

    deinit {
        // Clean up without calling MainActor-isolated stop()
        displayLink?.invalidate()
        audioEngine?.stop()
    }

    // MARK: - Public API

    func start() {
        guard !isPlaying else { return }

        setupAudioSession()
        setupAudioEngine()

        isPlaying = true
        currentBeat = 0
        nextBeatTime = CACurrentMediaTime()

        // Use display link for timing (more reliable than Timer)
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120)
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        isPlaying = false
        displayLink?.invalidate()
        displayLink = nil
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        currentBeat = 0
    }

    func toggle() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func tapTempo() {
        let now = Date()

        // Remove old taps
        tapTimes = tapTimes.filter { now.timeIntervalSince($0) < maxTapInterval }

        tapTimes.append(now)

        // Need at least 2 taps to calculate tempo
        guard tapTimes.count >= 2 else { return }

        // Calculate average interval from last N taps
        let recentTaps = Array(tapTimes.suffix(tapHistoryCount))
        var intervals: [TimeInterval] = []

        for i in 1..<recentTaps.count {
            intervals.append(recentTaps[i].timeIntervalSince(recentTaps[i-1]))
        }

        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let newBpm = Int(round(60.0 / averageInterval))

        bpm = newBpm
    }

    func setTimeSignature(_ signature: String) {
        // Parse "4/4", "3/4", "6/8", etc.
        let parts = signature.split(separator: "/")
        if let beats = Int(parts.first ?? "") {
            beatsPerMeasure = beats
        }
    }

    // MARK: - Private Methods

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("MetronomeEngine: Failed to setup audio session: \(error)")
        }
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let audioEngine = audioEngine, let playerNode = playerNode else { return }

        audioEngine.attach(playerNode)

        // Create click buffers
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        clickBuffer = generateClickBuffer(format: format, frequency: 880, duration: 0.05)   // A5
        accentBuffer = generateClickBuffer(format: format, frequency: 1760, duration: 0.05) // A6

        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("MetronomeEngine: Failed to start audio engine: \(error)")
        }
    }

    private func generateClickBuffer(format: AVAudioFormat, frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else {
            return nil
        }

        // Generate sine wave with envelope
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let envelope = exp(-time * 30) // Quick decay
            let sample = Float(sin(2.0 * .pi * frequency * time) * envelope * 0.5)
            channelData[frame] = sample
        }

        return buffer
    }

    @objc private func displayLinkFired() {
        guard isPlaying else { return }

        let currentTime = CACurrentMediaTime()

        if currentTime >= nextBeatTime {
            playBeat()
            nextBeatTime += beatInterval

            // If we've fallen behind, catch up
            if nextBeatTime < currentTime {
                nextBeatTime = currentTime + beatInterval
            }
        }
    }

    private func playBeat() {
        let isAccent = currentBeat == 0

        // Play audio
        if let playerNode = playerNode {
            let buffer = isAccent ? accentBuffer : clickBuffer
            if let buffer = buffer {
                playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            }
        }

        // Haptic feedback
        if isAccent {
            heavyImpactGenerator.impactOccurred()
        } else {
            impactGenerator.impactOccurred()
        }

        // Advance beat
        currentBeat = (currentBeat + 1) % beatsPerMeasure
    }
}
