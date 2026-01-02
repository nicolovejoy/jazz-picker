//
//  MetronomeOverlayView.swift
//  JazzPicker
//
//  Floating metronome control overlay for PDF viewer.
//

import SwiftUI

struct MetronomeOverlayView: View {
    @EnvironmentObject var metronomeStore: MetronomeStore
    @State private var showSettings = false

    var onInteraction: (() -> Void)?
    var onSettingsOpen: (() -> Void)?
    var onSettingsClose: (() -> Void)?

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    // Tempo slider binding
    private var bpmBinding: Binding<Double> {
        Binding(
            get: { Double(metronomeStore.engine.bpm) },
            set: { metronomeStore.engine.bpm = Int($0) }
        )
    }

    // Volume slider binding
    private var volumeBinding: Binding<Double> {
        Binding(
            get: { Double(metronomeStore.engine.volume) },
            set: { metronomeStore.engine.volume = Float($0) }
        )
    }

    // Time signature binding
    private var timeSignatureBinding: Binding<TimeSignature> {
        Binding(
            get: {
                TimeSignature(from: metronomeStore.currentTimeSignatureString) ?? .fourFour
            },
            set: { newValue in
                metronomeStore.engine.setTimeSignature(newValue)
            }
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header with settings and close buttons
            HStack {
                Button {
                    lightHaptic.impactOccurred()
                    onSettingsOpen?()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                if let style = metronomeStore.songTempoStyle {
                    Spacer()
                    Text(style)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    lightHaptic.impactOccurred()
                    metronomeStore.hide()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Volume slider
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
                Slider(value: volumeBinding, in: 0...1) { _ in
                    onInteraction?()
                }
                .tint(.white)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 20)
            }

            // Tempo display
            VStack(spacing: 4) {
                Text("\(metronomeStore.engine.bpm)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                Text("BPM")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }

            // Tempo slider
            Slider(value: bpmBinding, in: 20...420, step: 1) { _ in
                onInteraction?()
            }
            .tint(.white)

            // Meter picker
            Picker("Meter", selection: timeSignatureBinding) {
                ForEach(TimeSignature.allCases) { sig in
                    Text(sig.displayName).tag(sig)
                }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .onChange(of: timeSignatureBinding.wrappedValue) { _, _ in
                onInteraction?()
            }

            // Beat indicators
            HStack(spacing: 6) {
                ForEach(0..<metronomeStore.engine.beatsPerMeasure, id: \.self) { beat in
                    Circle()
                        .fill(beatColor(for: beat))
                        .frame(width: 14, height: 14)
                }
            }
            .animation(.easeInOut(duration: 0.05), value: metronomeStore.engine.currentBeat)

            // Play/Stop and Tap buttons
            HStack(spacing: 16) {
                Button {
                    mediumHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.engine.toggle()
                } label: {
                    Image(systemName: metronomeStore.engine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 50, height: 44)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.engine.tapTempo()
                } label: {
                    Text("Tap")
                        .font(.headline)
                        .frame(width: 70, height: 44)
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }

            // Reset to song defaults (if different)
            if metronomeStore.hasDifferentSettings {
                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.resetToSongDefaults()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption)
                        Text(resetButtonText)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(width: 280)
        .sheet(isPresented: $showSettings) {
            MetronomeSettingsView(onInteraction: onSettingsOpen)
                .presentationDetents([.medium])
        }
        .onChange(of: showSettings) { _, isOpen in
            if !isOpen {
                onSettingsClose?()
            }
        }
    }

    private func beatColor(for beat: Int) -> Color {
        guard metronomeStore.engine.isPlaying,
              beat == metronomeStore.engine.currentBeat else {
            return Color.white.opacity(0.2)
        }
        // Beat 1 (index 0) is orange, others are accent blue
        return beat == 0 ? Color.orange : Color.accentColor
    }

    private var resetButtonText: String {
        var parts: [String] = []
        if let songBpm = metronomeStore.songTempoBpm {
            parts.append("\(songBpm) BPM")
        }
        if let songTimeSig = metronomeStore.songTimeSignature {
            parts.append(songTimeSig)
        }
        if parts.isEmpty {
            return "Reset"
        }
        return "Reset to " + parts.joined(separator: ", ")
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()

        VStack {
            HStack {
                Spacer()
                MetronomeOverlayView()
                    .padding()
            }
            Spacer()
        }
    }
    .environmentObject(MetronomeStore())
}
