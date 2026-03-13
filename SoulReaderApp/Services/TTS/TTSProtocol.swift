import Foundation

/// Defines the contract every TTS engine must fulfil.
///
/// Conforming types are responsible for synthesising speech from text and
/// invoking the `completion` closure when a given utterance finishes.
/// The ``PlaybackController`` depends on this protocol rather than any
/// concrete engine, making it trivial to swap the native engine for the
/// neural one once it is ready.
protocol TTSProtocol: AnyObject {

    /// Synthesise and play `text`, calling `completion` when the utterance ends.
    ///
    /// - Parameters:
    ///   - text:       The string to be spoken.
    ///   - completion: Called on the main queue when the utterance finishes.
    func play(text: String, completion: @escaping () -> Void)

    /// Pause the current utterance mid-speech.
    func pause()

    /// Resume a previously paused utterance.
    func resume()

    /// Stop synthesis immediately and discard any buffered audio.
    func stop()
}
