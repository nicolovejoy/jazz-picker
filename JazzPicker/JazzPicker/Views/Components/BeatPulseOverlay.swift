//
//  BeatPulseOverlay.swift
//  JazzPicker
//
//  Visual beat indicator - pulsing edge band around sheet music.
//

import SwiftUI

struct BeatPulseOverlay: View {
    @EnvironmentObject var metronomeStore: MetronomeStore
    private let settings = MetronomeSettings.shared

    @State private var pulseOpacity: Double = 0
    @State private var isDownbeat: Bool = false

    var body: some View {
        GeometryReader { geometry in
            if settings.visualPulseEnabled && metronomeStore.engine.isPlaying {
                RoundedRectangle(cornerRadius: 0)
                    .strokeBorder(
                        pulseColor,
                        lineWidth: settings.visualIntensity.lineWidth
                    )
                    .opacity(pulseOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .onChange(of: metronomeStore.engine.currentBeat) { _, _ in
                        triggerPulse()
                    }
            }
        }
    }

    /// Beat 1 (downbeat) is orange, other beats use accent color
    private var pulseColor: Color {
        isDownbeat ? .orange : .accentColor
    }

    private func triggerPulse() {
        let targetOpacity = settings.visualIntensity.opacity
        isDownbeat = metronomeStore.engine.currentBeat == 0

        // Slightly brighter on downbeat
        let peakOpacity = isDownbeat ? min(targetOpacity * 1.3, 1.0) : targetOpacity

        withAnimation(.easeIn(duration: 0.05)) {
            pulseOpacity = peakOpacity
        }

        // Fade out over the beat duration (adjusted for tempo)
        let beatDuration = 60.0 / Double(metronomeStore.engine.bpm)
        let fadeOutDuration = min(beatDuration * 0.7, 0.3) // Cap at 300ms

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: fadeOutDuration)) {
                pulseOpacity = 0
            }
        }
    }
}

#Preview {
    ZStack {
        Color.white
        Text("Sheet Music Here")
            .font(.largeTitle)
        BeatPulseOverlay()
    }
    .environmentObject(MetronomeStore())
}
