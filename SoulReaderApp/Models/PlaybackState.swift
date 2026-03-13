import Foundation

/// Describes all possible states of the audio playback pipeline.
enum PlaybackState: Equatable {
    /// No book is loaded; the player is idle.
    case stopped
    /// Audio synthesis / buffering is in progress before audio starts.
    case buffering
    /// Audio is actively playing.
    case playing
    /// Playback is paused at a specific position (sentence index within a chapter).
    case paused(sentenceIndex: Int)
}
