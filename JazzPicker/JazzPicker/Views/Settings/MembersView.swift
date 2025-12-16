//
//  MembersView.swift
//  JazzPicker
//

import SwiftUI

struct MembersView: View {
    @Environment(BandStore.self) private var bandStore
    @Environment(UserProfileStore.self) private var userProfileStore

    let band: Band

    @State private var members: [BandMember] = []
    @State private var displayNames: [String: String] = [:]
    @State private var isLoading = true
    @State private var codeCopied = false

    var body: some View {
        List {
            Section {
                ForEach(members) { member in
                    HStack {
                        Text(displayNames[member.userId] ?? String(member.userId.prefix(8)) + "...")
                            .font(.subheadline)
                        Spacer()
                        if member.role == .admin {
                            Text("Admin")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
            } header: {
                Text("\(members.count) member\(members.count == 1 ? "" : "s")")
            }

            Section {
                Button(action: copyCode) {
                    HStack {
                        Text("Share Code")
                        Spacer()
                        Text(band.code)
                            .monospaced()
                            .foregroundStyle(.secondary)
                        if codeCopied {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
        .navigationTitle(band.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            members = await bandStore.getMembers(band.id)
            let userIds = members.map { $0.userId }
            displayNames = await userProfileStore.getDisplayNames(for: userIds)
            isLoading = false
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    private func copyCode() {
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
        MembersView(band: Band(name: "Test Band", code: "bebop-monk-cool"))
    }
    .environment(BandStore())
    .environment(UserProfileStore())
}
