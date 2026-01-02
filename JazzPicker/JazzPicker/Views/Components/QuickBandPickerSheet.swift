//
//  QuickBandPickerSheet.swift
//  JazzPicker
//
//  Quick band picker for starting Groove Sync from PDF viewer.
//

import SwiftUI

struct QuickBandPickerSheet: View {
    @EnvironmentObject private var bandStore: BandStore
    @EnvironmentObject private var grooveSyncStore: GrooveSyncStore
    @EnvironmentObject private var userProfileStore: UserProfileStore
    @Environment(\.dismiss) private var dismiss

    let onBandSelected: (String) -> Void

    private var lastUsedBandId: String? {
        userProfileStore.profile?.lastUsedGroupId
    }

    private var lastUsedBand: Band? {
        guard let id = lastUsedBandId else { return nil }
        return bandStore.bands.first { $0.id == id }
    }

    private var otherBands: [Band] {
        bandStore.bands.filter { $0.id != lastUsedBandId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bandStore.bands.isEmpty {
                    ContentUnavailableView(
                        "No Bands Yet",
                        systemImage: "person.3",
                        description: Text("Create or join a band in Settings to share charts")
                    )
                } else {
                    List {
                        // Show last used band first
                        if let band = lastUsedBand {
                            Section("Recent") {
                                bandRow(band)
                            }
                        }

                        // Other bands
                        if !otherBands.isEmpty {
                            Section(lastUsedBand == nil ? "Bands" : "All Bands") {
                                ForEach(otherBands) { band in
                                    bandRow(band)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share with Band")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func bandRow(_ band: Band) -> some View {
        Button {
            onBandSelected(band.id)
            dismiss()
        } label: {
            HStack {
                Text(band.name)
                    .foregroundColor(.primary)
                Spacer()

                // Show if someone is already sharing
                if let session = grooveSyncStore.activeSessionForGroup(band.id) {
                    Text("\(session.leaderName) is sharing")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    QuickBandPickerSheet { bandId in
        print("Selected band: \(bandId)")
    }
    .environmentObject(BandStore())
    .environmentObject(GrooveSyncStore())
    .environmentObject(UserProfileStore())
}
