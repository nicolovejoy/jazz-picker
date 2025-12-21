//
//  DeepLinkJoinView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct DeepLinkJoinView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var bandStore: BandStore

    let code: String

    @State private var band: Band?
    @State private var isLoading = true
    @State private var isJoining = false
    @State private var error: String?
    @State private var joined = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Looking up band...")
            } else if joined {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Joined \(band?.name ?? "band")")
                        .font(.headline)
                }
            } else if let band = band {
                VStack(spacing: 24) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)

                    Text("Join \(band.name)?")
                        .font(.title2)

                    Text("You'll see setlists shared by this band.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let error = error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button(action: joinBand) {
                        if isJoining {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Join Band")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isJoining)
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Band not found")
                        .font(.headline)
                    Text("The invite link may be invalid or expired.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: 400)
        .navigationTitle("Join Band")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(joined ? "Done" : "Cancel") {
                    dismiss()
                }
            }
        }
        .task {
            await lookupBand()
        }
    }

    private func lookupBand() async {
        do {
            band = try await BandFirestoreService.getBandByCode(code)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func joinBand() {
        guard let uid = authStore.user?.uid else { return }
        isJoining = true
        error = nil

        Task {
            if await bandStore.joinBand(code: code, userId: uid) != nil {
                joined = true
                // Auto-dismiss after a moment
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            } else {
                error = bandStore.error ?? "Failed to join band"
            }
            isJoining = false
        }
    }
}

#Preview {
    NavigationStack {
        DeepLinkJoinView(code: "bebop-monk-cool")
    }
    .environmentObject(AuthStore())
    .environmentObject(BandStore())
}
