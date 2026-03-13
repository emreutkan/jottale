import SwiftUI

/// A compact, persistent player bar shown at the bottom of the library screen.
struct MiniPlayerView: View {
    @EnvironmentObject var playbackController: PlaybackController
    @State private var isPlayerPresented = false

    var body: some View {
        HStack(spacing: 12) {
            // Book cover thumbnail
            coverThumbnail
                .frame(width: 44, height: 58)
                .cornerRadius(6)

            // Title & chapter
            VStack(alignment: .leading, spacing: 2) {
                Text(playbackController.currentBook?.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(playbackController.currentChapter?.title ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Play / Pause button
            Button {
                playbackController.togglePlayPause()
            } label: {
                Image(systemName: playbackController.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            // Stop button
            Button {
                playbackController.stop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .onTapGesture {
            isPlayerPresented = true
        }
        .sheet(isPresented: $isPlayerPresented) {
            PlayerView()
                .environmentObject(playbackController)
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var coverThumbnail: some View {
        if let coverPath = playbackController.currentBook?.coverImagePath,
           let uiImage = UIImage(contentsOfFile: coverPath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.indigo.opacity(0.7), .purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MiniPlayerView()
        .environmentObject(PlaybackController())
}
