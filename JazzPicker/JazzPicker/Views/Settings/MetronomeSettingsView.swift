//
//  MetronomeSettingsView.swift
//  JazzPicker
//
//  Settings for metronome sound and visual feedback.
//

import SwiftUI

struct MetronomeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = MetronomeSettings.shared

    var onInteraction: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    ForEach(MetronomeSoundType.allCases) { soundType in
                        Button {
                            onInteraction?()
                            settings.soundType = soundType
                        } label: {
                            HStack {
                                Image(systemName: soundType.iconName)
                                    .frame(width: 24)
                                    .foregroundStyle(.primary)
                                Text(soundType.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if settings.soundType == soundType {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }

                Section("Visual Beat Pulse") {
                    Toggle("Show Visual Pulse", isOn: $settings.visualPulseEnabled)
                        .onChange(of: settings.visualPulseEnabled) { _, _ in
                            onInteraction?()
                        }

                    if settings.visualPulseEnabled {
                        ForEach(VisualPulseIntensity.allCases) { intensity in
                            Button {
                                onInteraction?()
                                settings.visualIntensity = intensity
                            } label: {
                                HStack {
                                    Text(intensity.rawValue)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if settings.visualIntensity == intensity {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(
                                    Color.accentColor,
                                    lineWidth: settings.visualIntensity.lineWidth
                                )
                                .opacity(settings.visualPulseEnabled ? settings.visualIntensity.opacity : 0.1)
                                .frame(width: 100, height: 60)
                            Text("Preview")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Pulse Preview")
                }
            }
            .navigationTitle("Metronome Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MetronomeSettingsView()
}
