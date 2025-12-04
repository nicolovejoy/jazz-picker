//
//  SettingsView.swift
//  JazzPicker
//

import SwiftUI

struct BuildEntry: Codable {
    let build: Int
    let date: String
    let notes: String
}

struct SettingsView: View {
    @Binding var selectedInstrument: String

    var instrument: Instrument {
        Instrument(rawValue: selectedInstrument) ?? .piano
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    private var buildHistory: [BuildEntry] {
        guard let url = Bundle.main.url(forResource: "BuildHistory", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([BuildEntry].self, from: data) else {
            return []
        }
        return Array(entries.prefix(3))
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
                        Text("\(version) (\(buildNumber))")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://jazz-picker.fly.dev")!) {
                        Text("Backend API")
                    }
                }

                if !buildHistory.isEmpty {
                    Section("Recent Updates") {
                        ForEach(buildHistory, id: \.build) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Build \(entry.build)")
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(entry.date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(entry.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
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
