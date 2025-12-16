//
//  GroupsSection.swift
//  JazzPicker
//

import SwiftUI

struct GroupsSection: View {
    @Environment(BandStore.self) private var bandStore

    private var bandsSummary: String {
        let bands = bandStore.bands
        if bands.isEmpty {
            return "No bands yet"
        } else if bands.count <= 2 {
            return bands.map(\.name).joined(separator: ", ")
        } else {
            return "\(bands.count) bands"
        }
    }

    var body: some View {
        Section("Bands") {
            NavigationLink {
                BandsManagementView()
            } label: {
                HStack {
                    Text("Bands")
                    Spacer()
                    Text(bandsSummary)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            GroupsSection()
        }
    }
    .environment(BandStore())
}
