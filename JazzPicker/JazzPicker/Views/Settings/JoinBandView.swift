//
//  JoinBandView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct JoinBandView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var bandStore: BandStore

    @State private var code = ""
    @State private var isJoining = false

    var body: some View {
        Form {
            Section {
                TextField("Band Code", text: $code)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .monospaced()
            } footer: {
                Text("Ask your bandmate for the code (e.g., bebop-monk-cool)")
            }

            if let error = bandStore.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationTitle("Join Band")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isJoining)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Join") { joinBand() }
                    .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)
            }
        }
        .onAppear {
            bandStore.clearError()
        }
    }

    private func joinBand() {
        guard let uid = authStore.user?.uid else { return }
        bandStore.clearError()
        isJoining = true

        Task {
            if await bandStore.joinBand(code: code, userId: uid) != nil {
                dismiss()
            }
            isJoining = false
        }
    }
}

#Preview {
    NavigationStack {
        JoinBandView()
    }
    .environmentObject(AuthStore())
    .environmentObject(BandStore())
}
