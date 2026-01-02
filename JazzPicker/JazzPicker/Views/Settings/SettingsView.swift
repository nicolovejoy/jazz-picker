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
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @EnvironmentObject private var pdfCacheService: PDFCacheService
    @EnvironmentObject private var bandStore: BandStore
    @EnvironmentObject private var grooveSyncStore: GrooveSyncStore
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
        return Array(entries.prefix(10))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("settings-bg")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.08)

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

                Section("Metronome") {
                    NavigationLink {
                        MetronomeSettingsView()
                    } label: {
                        HStack {
                            Text("Sound")
                            Spacer()
                            Text(MetronomeSettings.shared.soundType.rawValue)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Groove Sync") {
                    Toggle(isOn: $grooveSyncStore.page2ModeEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Page 2 Mode")
                            Text("When following, show leader's next page")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                    NavigationLink {
                        AboutView()
                    } label: {
                        Text("How to Use")
                    }

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
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
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
}

// MARK: - Instrument Picker

struct InstrumentPickerView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedInstrument: Instrument = .piano
    @State private var isSaving = false

    var body: some View {
        Form {
            InstrumentPickerContent(selectedInstrument: $selectedInstrument)
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
        .environmentObject(AuthStore())
        .environmentObject(UserProfileStore())
        .environmentObject(PDFCacheService.shared)
        .environmentObject(BandStore())
        .environmentObject(NetworkMonitor())
        .environmentObject(GrooveSyncStore())
}
