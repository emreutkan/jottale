import SwiftUI

/// Full "Now Playing" screen with chapter info, play/pause, and a sentence scrubber.
struct PlayerView: View {
    @EnvironmentObject var playbackController: PlaybackController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Cover art
                coverArt
                    .frame(width: 240, height: 320)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)

                // Title & Author
                VStack(spacing: 4) {
                    Text(playbackController.currentBook?.title ?? "—")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(playbackController.currentBook?.author ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Chapter name
                if let chapter = playbackController.currentChapter {
                    Text(chapter.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress scrubber
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { Double(playbackController.currentSentenceIndex) },
                            set: { playbackController.seek(toSentenceIndex: Int($0)) }
                        ),
                        in: 0...Double(max(playbackController.sentenceCount - 1, 1)),
                        step: 1
                    )

                    HStack {
                        Text("Sentence \(playbackController.currentSentenceIndex + 1)")
                        Spacer()
                        Text("of \(playbackController.sentenceCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                // Transport controls
                HStack(spacing: 48) {
                    Button {
                        playbackController.previousChapter()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title)
                    }

                    Button {
                        playbackController.togglePlayPause()
                    } label: {
                        Image(systemName: playbackController.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                    }

                    Button {
                        playbackController.nextChapter()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title)
                    }
                }
                .foregroundColor(.primary)

                Spacer()
            }
            .padding()
            .navigationTitle("Now Playing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Cover Art

    @ViewBuilder
    private var coverArt: some View {
        if let coverPath = playbackController.currentBook?.coverImagePath,
           let uiImage = UIImage(contentsOfFile: coverPath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.indigo.opacity(0.7), .purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PlayerView()
        .environmentObject(PlaybackController())
}
