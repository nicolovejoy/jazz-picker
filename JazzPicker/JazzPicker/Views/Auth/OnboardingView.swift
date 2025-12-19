//
//  OnboardingView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct OnboardingView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UserProfileStore.self) private var userProfileStore

    @State private var selectedInstrument: Instrument = .piano
    @State private var displayName: String = ""
    @State private var isSaving = false

    private let concertPitchInstruments: [Instrument] = [.piano, .guitar]
    private let bbInstruments: [Instrument] = [.trumpet, .clarinet, .tenorSax, .sopranoSax]
    private let ebInstruments: [Instrument] = [.altoSax, .bariSax]
    private let bassClefInstruments: [Instrument] = [.bass, .trombone]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Your Name")
                } footer: {
                    Text("How you'll appear to bandmates")
                }

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

                if let error = userProfileStore.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
            .navigationTitle("Welcome")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Continue") {
                            saveProfile()
                        }
                        .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
        .onAppear {
            prefillDisplayName()
        }
        .interactiveDismissDisabled()
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

    private func prefillDisplayName() {
        // Try to get display name from Firebase user (Apple provides this on first sign-in)
        if let user = authStore.user, let name = user.displayName, !name.isEmpty {
            displayName = name
        }
    }

    private func saveProfile() {
        guard let uid = authStore.user?.uid else { return }

        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isSaving = true

        Task {
            await userProfileStore.createProfile(
                uid: uid,
                instrument: selectedInstrument,
                displayName: trimmedName
            )
            isSaving = false
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AuthStore())
        .environment(UserProfileStore())
}
