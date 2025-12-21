//
//  BandsManagementView.swift
//  JazzPicker
//

import FirebaseAuth
import SwiftUI

struct BandsManagementView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var bandStore: BandStore
    @EnvironmentObject private var setlistStore: SetlistStore
    @EnvironmentObject private var networkMonitor: NetworkMonitor

    @State private var bandToLeave: Band?
    @State private var bandToDelete: Band?
    @State private var deleteBlockedBand: Band?
    @State private var bandToShare: Band?

    private func setlistCount(for bandId: String) -> Int {
        setlistStore.setlists.filter { $0.groupId == bandId }.count
    }

    var body: some View {
        List {
            if let error = bandStore.error {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if bandStore.bands.isEmpty && bandStore.error == nil {
                ContentUnavailableView {
                    Label("No Bands", systemImage: "person.3")
                } description: {
                    Text("Create or join a band to share setlists")
                }
                .listRowBackground(Color.clear)
            } else {
                Section("Your Bands") {
                    ForEach(bandStore.bands) { band in
                        NavigationLink {
                            MembersView(band: band)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(band.name)
                                    .font(.headline)
                                Text(band.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospaced()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                handleDeleteTap(band)
                            }

                            Button("Leave") {
                                bandToLeave = band
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                bandToShare = band
                            } label: {
                                Label("Invite", systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
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
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
        .navigationTitle("Bands")
        // Leave alert
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
        // Delete alert
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
        // Delete blocked alert (has setlists)
        .alert("Can't Delete Band", isPresented: .init(
            get: { deleteBlockedBand != nil },
            set: { if !$0 { deleteBlockedBand = nil } }
        )) {
            Button("OK") { deleteBlockedBand = nil }
        } message: {
            if let band = deleteBlockedBand {
                let count = setlistCount(for: band.id)
                Text("\(band.name) has \(count) setlist\(count == 1 ? "" : "s"). Delete them first.")
            }
        }
        // Share sheet for inviting to band
        .sheet(item: $bandToShare) { band in
            InviteToBandSheet(band: band)
        }
    }

    private func handleDeleteTap(_ band: Band) {
        let count = setlistCount(for: band.id)
        if count > 0 {
            deleteBlockedBand = band
        } else {
            bandToDelete = band
        }
    }
}

// MARK: - Invite Sheet

struct InviteToBandSheet: View {
    let band: Band
    @Environment(\.dismiss) private var dismiss

    private var inviteMessage: String {
        "Join my band \"\(band.name)\" on Jazz Picker!\n\nCode: \(band.code)\n\nhttps://jazzpicker.pianohouseproject.org/?join=\(band.code)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Invite to \(band.name)")
                        .font(.headline)

                    Text("Share this code with your bandmates:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Band code display
                Text(band.code)
                    .font(.title)
                    .fontDesign(.monospaced)
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Share button
                ShareLink(item: inviteMessage) {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BandsManagementView()
    }
    .environmentObject(AuthStore())
    .environmentObject(BandStore())
    .environmentObject(SetlistStore())
    .environmentObject(NetworkMonitor())
}
