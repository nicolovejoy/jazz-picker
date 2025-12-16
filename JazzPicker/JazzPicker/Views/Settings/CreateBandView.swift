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

                        Text("Share this code with your band:")
                            .foregroundStyle(.secondary)

                        Button(action: copyCode) {
                            HStack {
                                Text(band.code)
                                    .font(.title2.monospaced())
                                Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                    .foregroundStyle(codeCopied ? .green : .accentColor)
                            }
                            .padding()
                            .background(.secondary.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
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

    private func copyCode() {
        guard let band = createdBand else { return }
        UIPasteboard.general.string = band.code
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
