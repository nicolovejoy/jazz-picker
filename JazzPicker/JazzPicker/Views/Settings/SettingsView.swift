//
//  SettingsView.swift
//  JazzPicker
//

import SwiftUI

struct SettingsView: View {
    @Binding var selectedInstrument: String

    var instrument: Instrument {
        Instrument(rawValue: selectedInstrument) ?? .piano
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Instrument") {
                    Picker("Instrument", selection: $selectedInstrument) {
                        ForEach(Instrument.allCases) { inst in
                            Text(inst.label).tag(inst.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    HStack {
                        Text("Transposition")
                        Spacer()
                        Text(instrument.transposition.rawValue)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Clef")
                        Spacer()
                        Text(instrument.clef.rawValue.capitalized)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://jazz-picker.fly.dev")!) {
                        Text("Backend API")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(selectedInstrument: .constant(Instrument.trumpet.rawValue))
}
