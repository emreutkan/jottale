import Foundation
import AVFoundation

/// Configures and manages the shared `AVAudioSession` so that audio playback
/// continues when the app is backgrounded or the screen is locked.
final class AudioSessionManager {

    // MARK: - Public API

    /// Activates the audio session with `.playback` category and background audio capability.
    func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            print("[AudioSessionManager] Failed to activate session: \(error.localizedDescription)")
        }
    }

    /// Deactivates the audio session and notifies other audio consumers.
    func deactivate() {
        do {
            try AVAudioSession.sharedInstance()
                .setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AudioSessionManager] Failed to deactivate session: \(error.localizedDescription)")
        }
    }
}
