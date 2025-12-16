//
//  GroupsSection.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct GroupsSection: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(BandStore.self) private var bandStore
    @Environment(NetworkMonitor.self) private var networkMonitor

    @State private var bandToLeave: Band?
    @State private var bandToDelete: Band?
    @State private var copiedBandId: String?

    var body: some View {
        Section("Bands") {
            if let error = bandStore.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if bandStore.bands.isEmpty && bandStore.error == nil {
                ContentUnavailableView {
                    Label("No Bands", systemImage: "person.3")
                } description: {
                    Text("Create or join a band to share setlists")
                }
                .listRowBackground(Color.clear)
            } else if !bandStore.bands.isEmpty {
                ForEach(bandStore.bands) { band in
                    BandRow(
                        band: band,
                        isCopied: copiedBandId == band.id,
                        onCopyCode: { copyCode(band) },
                        onLeave: { checkMemberCountAndPrompt(band) }
                    )
                }
            }

        }
        .navigationDestination(for: Band.self) { band in
            MembersView(band: band)
        }

        Section {
            NavigationLink {
                CreateBandView()
            } label: {
                Label("Create Band", systemImage: "plus.circle")
            }

            NavigationLink {
                JoinBandView()
            } label: {
                Label("Join Band", systemImage: "person.badge.plus")
            }
        }
        .disabled(!networkMonitor.isConnected)
        // Leave alert (multiple members)
        .alert("Leave Band?", isPresented: .init(
            get: { bandToLeave != nil },
            set: { if !$0 { bandToLeave = nil } }
        )) {
            Button("Cancel", role: .cancel) { bandToLeave = nil }
            Button("Leave", role: .destructive) {
                if let band = bandToLeave, let uid = authStore.user?.uid {
                    Task { await bandStore.leaveBand(band.id, userId: uid) }
                }
                bandToLeave = nil
            }
        } message: {
            if let band = bandToLeave {
                Text("You'll no longer see setlists from \(band.name).")
            }
        }
        // Delete alert (sole member)
        .alert("Delete Band?", isPresented: .init(
            get: { bandToDelete != nil },
            set: { if !$0 { bandToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { bandToDelete = nil }
            Button("Delete", role: .destructive) {
                if let band = bandToDelete, let uid = authStore.user?.uid {
                    Task { await bandStore.deleteBand(band.id, userId: uid) }
                }
                bandToDelete = nil
            }
        } message: {
            if let band = bandToDelete {
                Text("This will permanently delete \(band.name). This cannot be undone.")
            }
        }
    }

    private func checkMemberCountAndPrompt(_ band: Band) {
        Task {
            let count = await bandStore.getMemberCount(band.id)
            await MainActor.run {
                if count <= 1 {
                    bandToDelete = band
                } else {
                    bandToLeave = band
                }
            }
        }
    }

    private func copyCode(_ band: Band) {
        UIPasteboard.general.string = band.code
        copiedBandId = band.id
        Task {
            try? await Task.sleep(for: .seconds(2))
            if copiedBandId == band.id {
                copiedBandId = nil
            }
        }
    }
}

struct BandRow: View {
    let band: Band
    let isCopied: Bool
    let onCopyCode: () -> Void
    let onLeave: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(band.name)
                    .font(.headline)
                Text(band.code)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            Spacer()
            Button(action: onCopyCode) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? .green : .accentColor)
            }
            .buttonStyle(.borderless)
            NavigationLink(value: band) {
                Image(systemName: "person.3")
            }
            .buttonStyle(.borderless)
            Button(action: onLeave) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.borderless)
            .tint(.red)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            GroupsSection()
        }
    }
    .environment(AuthStore())
    .environment(BandStore())
    .environment(NetworkMonitor())
}
