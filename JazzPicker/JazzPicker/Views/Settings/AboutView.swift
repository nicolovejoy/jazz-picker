//
//  AboutView.swift
//  JazzPicker
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jazz Picker")
                        .font(.largeTitle.weight(.bold))
                    Text("750+ jazz lead sheets, transposed for your instrument")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Setlists
                featureSection(
                    icon: "music.note.list",
                    title: "Setlists",
                    content: """
                    Create setlists to organize songs for a gig. Tap the Setlists tab, then + to create one. \
                    Add songs from the PDF viewer using the "Add to Setlist" menu option. \
                    Reorder songs by dragging, or swipe to delete. \
                    Each song in a setlist remembers its key and octave offset.
                    """
                )

                // Bands
                featureSection(
                    icon: "person.3",
                    title: "Bands",
                    content: """
                    Bands let you share setlists with other musicians. Go to Settings > Bands to create one. \
                    Share the join code with bandmates - they enter it in Settings > Join Band. \
                    Everyone in the band sees the same setlists, synced in real-time. \
                    When you create a setlist, pick which band it belongs to.
                    """
                )

                // Groove Sync
                featureSection(
                    icon: "music.note",
                    title: "Groove Sync",
                    content: """
                    Share your charts live during a gig. Open a setlist and tap "Share Charts" to start leading. \
                    Bandmates on their devices will see a prompt to follow along. \
                    As you open songs, they appear on followers' screens - automatically transposed for each player's instrument. \
                    Great for calling tunes or keeping everyone on the same page.
                    """
                )

                Spacer(minLength: 40)
            }
            .padding(24)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("How to Use")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func featureSection(icon: String, title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 32)
                Text(title)
                    .font(.title3.weight(.semibold))
            }

            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
