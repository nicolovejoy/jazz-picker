//
//  CreateBandView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct CreateBandView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var authStore
    @Environment(BandStore.self) private var bandStore

    @State private var name = ""
    @State private var isCreating = false
    @State private var createdBand: Band?
    @State private var codeCopied = false

    var body: some View {
        Form {
            if let band = createdBand {
                // Success state
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)

                        Text("\(band.name) created!")
                            .font(.headline)

                        Text("Share this invite with your band:")
                            .foregroundStyle(.secondary)

                        Button(action: copyInvite) {
                            HStack {
                                Text("Copy Invite Link")
                                Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                    .foregroundStyle(codeCopied ? .green : .accentColor)
                            }
                            .padding()
                            .background(.secondary.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Text(band.code)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            } else {
                Section {
                    TextField("Band Name", text: $name)
                        .textInputAutocapitalization(.words)
                } footer: {
                    Text("e.g., Friday Jazz Trio")
                }

                if let error = bandStore.error {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationTitle(createdBand != nil ? "Band Created" : "Create Band")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(createdBand != nil || isCreating)
        .toolbar {
            if createdBand != nil {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createBand() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                }
            }
        }
        .onAppear {
            bandStore.clearError()
        }
    }

    private func createBand() {
        guard let uid = authStore.user?.uid else { return }
        bandStore.clearError()
        isCreating = true

        Task {
            if let band = await bandStore.createBand(name: name, userId: uid) {
                createdBand = band
            }
            isCreating = false
        }
    }

    private func copyInvite() {
        guard let band = createdBand else { return }
        let message = "Please join my band \"\(band.name)\" on Jazz Picker: https://jazzpicker.pianohouseproject.org/?join=\(band.code)"
        UIPasteboard.general.string = message
        codeCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            codeCopied = false
        }
    }
}

#Preview {
    NavigationStack {
        CreateBandView()
    }
    .environment(AuthStore())
    .environment(BandStore())
}
