//
//  GrooveSyncModal.swift
//  JazzPicker
//

import SwiftUI

struct GrooveSyncModal: View {
    let session: GrooveSyncSession
    let onJoin: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())

            // Title
            Text("\(session.leaderName) is sharing charts")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Description
            Text("Follow along to see the same charts, transposed for your instrument.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Buttons
            HStack(spacing: 12) {
                Button("Not now") {
                    onDismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(10)

                Button("Follow") {
                    onJoin()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundColor(.white)
                .fontWeight(.medium)
                .cornerRadius(10)
            }
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 20)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        GrooveSyncModal(
            session: GrooveSyncSession(
                groupId: "test",
                leaderId: "leader123",
                leaderName: "Nico"
            ),
            onJoin: {},
            onDismiss: {}
        )
    }
}
