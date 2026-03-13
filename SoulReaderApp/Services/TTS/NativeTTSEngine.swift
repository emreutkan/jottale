import Foundation
import AVFoundation

/// A TTS engine backed by Apple's built-in `AVSpeechSynthesizer`.
///
/// Use this engine during development to validate the full app flow
/// (ePub parsing, chapter navigation, background audio, UI updates)
/// without requiring any ML model files.
///
/// Once the app works end-to-end with this engine, swap it for
/// ``NeuralTTSEngine`` in `PlaybackController.init(engine:)`.
final class NativeTTSEngine: NSObject, TTSProtocol {

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    private var completionHandler: (() -> Void)?

    // MARK: - Init

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - TTSProtocol

    func play(text: String, completion: @escaping () -> Void) {
        completionHandler = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        synthesizer.continueSpeaking()
    }

    func stop() {
        completionHandler = nil
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension NativeTTSEngine: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didFinish utterance: AVSpeechUtterance) {
        let handler = completionHandler
        completionHandler = nil
        DispatchQueue.main.async { handler?() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                           didCancel utterance: AVSpeechUtterance) {
        completionHandler = nil
    }
}
