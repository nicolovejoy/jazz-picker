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
                    Text("750+ jazz lead sheets for your gig")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Browse & Play
                featureSection(
                    icon: "magnifyingglass",
                    title: "Browse & Play",
                    content: """
                    Search songs by title. Tap to open the chart. \
                    Tap the key button to transpose - pick any of 12 keys. \
                    Use octave offset (±2) if notes land too high or low for your range.
                    """
                )

                // Transposition
                featureSection(
                    icon: "arrow.left.arrow.right",
                    title: "Transposition",
                    content: """
                    Set your instrument in Settings. Charts auto-transpose to your written key. \
                    Trumpet and clarinet see B♭ parts, alto sax sees E♭, bass sees bass clef.
                    """
                )

                // Setlists
                featureSection(
                    icon: "music.note.list",
                    title: "Setlists",
                    content: """
                    Organize songs for a gig. Add songs via the menu button while viewing a chart. \
                    Each setlist item remembers its key and octave. Reorder by dragging.
                    """
                )

                // Bands
                featureSection(
                    icon: "person.3",
                    title: "Bands",
                    content: """
                    Share setlists with bandmates. Create a band in Settings and share the join code. \
                    Everyone sees the same setlists, synced live.
                    """
                )

                // Groove Sync
                featureSection(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "Groove Sync",
                    content: """
                    Lead charts during a gig. Open a setlist, tap "Share Charts." \
                    Bandmates following along see each song you open, auto-transposed for their instrument.
                    """
                )

                // Offline
                featureSection(
                    icon: "arrow.down.circle",
                    title: "Offline Mode",
                    content: """
                    PDFs cache automatically after viewing. Check Settings > Offline Storage. \
                    Pre-load a setlist before a gig to ensure everything's available without wifi.
                    """
                )

                // Sculpture
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.top, 8)
                    Image("ForgePic3-about")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(0.8)
                }

                // Credits
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.top, 8)
                    Text("Lead sheets by Eric, typeset in LilyPond.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("App by Nico — The Piano House Project")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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
