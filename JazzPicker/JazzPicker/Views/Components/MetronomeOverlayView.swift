//
//  MetronomeOverlayView.swift
//  JazzPicker
//
//  Floating metronome control overlay for PDF viewer.
//

import SwiftUI

struct MetronomeOverlayView: View {
    @EnvironmentObject var metronomeStore: MetronomeStore

    var body: some View {
        VStack(spacing: 12) {
            // Header with close button
            HStack {
                if let style = metronomeStore.songTempoStyle {
                    Text(style)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
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
                    metronomeStore.engine.toggle()
                } label: {
                    Image(systemName: metronomeStore.engine.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)

                Button {
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
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(width: 200)
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
