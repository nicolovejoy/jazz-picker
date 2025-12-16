//
//  SettingsView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct BuildEntry: Codable {
    let build: Int
    let date: String
    let notes: String
}

struct SettingsView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(PDFCacheService.self) private var pdfCacheService
    @Environment(BandStore.self) private var bandStore
    @State private var showClearCacheConfirm = false
    @State private var showSignOutConfirm = false

    var instrument: Instrument {
        userProfileStore.profile?.instrument ?? .piano
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
                Section("Account") {
                    if let user = authStore.user {
                        HStack {
                            Text("Signed in as")
                            Spacer()
                            Text(user.email ?? "Unknown")
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let profile = userProfileStore.profile {
                        HStack {
                            Text("Display Name")
                            Spacer()
                            Text(profile.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Text("Sign Out")
                    }
                }

                GroupsSection()

                Section("Instrument") {
                    NavigationLink {
                        InstrumentPickerView()
                    } label: {
                        HStack {
                            Text("Instrument")
                            Spacer()
                            Text(instrument.label)
                                .foregroundStyle(.secondary)
                        }
                    }

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

                Section("Offline Storage") {
                    HStack {
                        Text("Cached Songs")
                        Spacer()
                        Text("\(pdfCacheService.cachedCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Storage Used")
                        Spacer()
                        Text(pdfCacheService.formattedCacheSize)
                            .foregroundStyle(.secondary)
                    }

                    Button(role: .destructive) {
                        showClearCacheConfirm = true
                    } label: {
                        Text("Clear Cache")
                    }
                    .disabled(pdfCacheService.cachedCount == 0)
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
            .alert("Clear Cache?", isPresented: $showClearCacheConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    pdfCacheService.clearCache()
                }
            } message: {
                Text("This will remove all \(pdfCacheService.cachedCount) cached songs. They will be re-downloaded when you view them.")
            }
            .alert("Sign Out?", isPresented: $showSignOutConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authStore.signOut()
                }
            } message: {
                Text("You'll need to sign in again to access your setlists.")
            }
        }
    }
}

// MARK: - Instrument Picker

struct InstrumentPickerView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserProfileStore.self) private var userProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedInstrument: Instrument = .piano
    @State private var isSaving = false

    private let concertPitchInstruments: [Instrument] = [.piano, .guitar]
    private let bbInstruments: [Instrument] = [.trumpet, .clarinet, .tenorSax, .sopranoSax]
    private let ebInstruments: [Instrument] = [.altoSax, .bariSax]
    private let bassClefInstruments: [Instrument] = [.bass, .trombone]

    var body: some View {
        Form {
            Section("Concert Pitch") {
                ForEach(concertPitchInstruments) { instrument in
                    instrumentRow(instrument)
                }
            }

            Section("B♭ Instruments") {
                ForEach(bbInstruments) { instrument in
                    instrumentRow(instrument)
                }
            }

            Section("E♭ Instruments") {
                ForEach(ebInstruments) { instrument in
                    instrumentRow(instrument)
                }
            }

            Section("Bass Clef") {
                ForEach(bassClefInstruments) { instrument in
                    instrumentRow(instrument)
                }
            }
        }
        .navigationTitle("Instrument")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let current = userProfileStore.profile?.instrument {
                selectedInstrument = current
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Save") {
                        saveInstrument()
                    }
                    .disabled(selectedInstrument == userProfileStore.profile?.instrument)
                }
            }
        }
    }

    @ViewBuilder
    private func instrumentRow(_ instrument: Instrument) -> some View {
        Button {
            selectedInstrument = instrument
        } label: {
            HStack {
                Text(instrument.label)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedInstrument == instrument {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }

    private func saveInstrument() {
        guard let uid = authStore.user?.uid else { return }

        isSaving = true

        Task {
            await userProfileStore.updateInstrument(uid: uid, instrument: selectedInstrument)
            isSaving = false
            dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environment(AuthStore())
        .environment(UserProfileStore())
        .environment(PDFCacheService.shared)
        .environment(BandStore())
        .environment(NetworkMonitor())
}
