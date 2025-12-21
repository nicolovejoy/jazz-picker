//
//  MembersView.swift
//  JazzPicker
//

import SwiftUI

struct MembersView: View {
    @EnvironmentObject private var bandStore: BandStore
    @EnvironmentObject private var userProfileStore: UserProfileStore

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
                Button(action: copyInvite) {
                    HStack {
                        Text("Copy Invite Link")
                        Spacer()
                        if codeCopied {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text(band.code)
                    .monospaced()
            }
        }
        .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
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

    private func copyInvite() {
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
        MembersView(band: Band(name: "Test Band", code: "bebop-monk-cool"))
    }
    .environmentObject(BandStore())
    .environmentObject(UserProfileStore())
}
