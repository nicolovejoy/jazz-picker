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

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(spacing: 12) {
            // Header with settings and close buttons
            HStack {
                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                if let style = metronomeStore.songTempoStyle {
                    Spacer()
                    Text(style)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    lightHaptic.impactOccurred()
                    metronomeStore.hide()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Tempo display with +/- buttons
            HStack(spacing: 16) {
                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.engine.bpm -= 5
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text("\(metronomeStore.engine.bpm)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("BPM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 80)

                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.engine.bpm += 5
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }

            // Beat indicators
            HStack(spacing: 8) {
                ForEach(0..<metronomeStore.engine.beatsPerMeasure, id: \.self) { beat in
                    Circle()
                        .fill(beat == metronomeStore.engine.currentBeat && metronomeStore.engine.isPlaying
                              ? Color.accentColor
                              : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
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
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.engine.tapTempo()
                } label: {
                    Text("Tap")
                        .font(.headline)
                        .frame(width: 60, height: 44)
                }
                .buttonStyle(.bordered)
            }

            // Reset to song tempo (if different)
            if metronomeStore.hasDifferentTempo, let songBpm = metronomeStore.songTempoBpm {
                Button {
                    lightHaptic.impactOccurred()
                    onInteraction?()
                    metronomeStore.resetToSongTempo()
                } label: {
                    Text("Reset to \(songBpm)")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(width: 220)
        .sheet(isPresented: $showSettings) {
            MetronomeSettingsView()
                .presentationDetents([.medium])
        }
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
