import Foundation
import Combine

/// The central brain of the app – coordinates the TTS engine, audio session,
/// sentence queue, and chapter navigation.
///
/// The ``PlaybackController`` owns:
/// - The currently loaded ``Book`` and its ``Chapter`` list
/// - The current sentence-level position inside a chapter
/// - The ``TTSProtocol``-conforming engine (swappable at runtime)
final class PlaybackController: ObservableObject {

    // MARK: - Published State

    @Published private(set) var currentBook: Book?
    @Published private(set) var currentChapter: Chapter?
    @Published private(set) var playbackState: PlaybackState = .stopped

    /// Index of the sentence currently being spoken within `currentChapter`.
    @Published private(set) var currentSentenceIndex: Int = 0

    // MARK: - Derived helpers (used by views)

    var isPlaying: Bool { playbackState == .playing }

    var sentenceCount: Int { sentences.count }

    // MARK: - Private

    private var chapters: [Chapter] = []
    private var sentences: [String] = []
    private var ttsEngine: TTSProtocol
    private let audioSessionManager = AudioSessionManager()

    // MARK: - Init

    /// Creates a ``PlaybackController`` with the given TTS engine.
    ///
    /// Defaults to the ``NativeTTSEngine`` so the app works immediately without
    /// any model files. Swap to ``NeuralTTSEngine`` when ready.
    init(engine: TTSProtocol = NativeTTSEngine()) {
        self.ttsEngine = engine
    }

    // MARK: - Public API

    /// Loads a book and its chapters, ready for playback from the first sentence.
    func load(book: Book, chapters: [Chapter]) {
        stop()
        currentBook = book
        self.chapters = chapters
        guard !chapters.isEmpty else { return }
        loadChapter(at: 0)
    }

    /// Toggles between playing and paused states.
    func togglePlayPause() {
        switch playbackState {
        case .playing:
            pause()
        case .paused, .stopped, .buffering:
            play()
        }
    }

    /// Begins or resumes playback from the current sentence position.
    func play() {
        guard !sentences.isEmpty else { return }
        audioSessionManager.activate()
        playbackState = .playing
        speakCurrentSentence()
    }

    /// Pauses playback and records the current sentence position.
    func pause() {
        ttsEngine.pause()
        playbackState = .paused(sentenceIndex: currentSentenceIndex)
    }

    /// Stops playback entirely and resets state.
    func stop() {
        ttsEngine.stop()
        playbackState = .stopped
        currentBook = nil
        currentChapter = nil
        sentences = []
        chapters = []
        currentSentenceIndex = 0
        audioSessionManager.deactivate()
    }

    /// Seeks to a specific sentence by index within the current chapter.
    func seek(toSentenceIndex index: Int) {
        guard index >= 0, index < sentences.count else { return }
        ttsEngine.stop()
        currentSentenceIndex = index
        if isPlaying {
            speakCurrentSentence()
        }
    }

    /// Jumps to the next chapter, if one exists.
    func nextChapter() {
        guard let current = currentChapter else { return }
        let nextIndex = current.index + 1
        guard nextIndex < chapters.count else { return }
        loadChapter(at: nextIndex)
        if isPlaying { play() }
    }

    /// Jumps back to the previous chapter, if one exists.
    func previousChapter() {
        guard let current = currentChapter else { return }
        let prevIndex = current.index - 1
        guard prevIndex >= 0 else { return }
        loadChapter(at: prevIndex)
        if isPlaying { play() }
    }

    // MARK: - Private Helpers

    private func loadChapter(at index: Int) {
        ttsEngine.stop()
        currentChapter = chapters[index]
        sentences = splitIntoSentences(chapters[index].content)
        currentSentenceIndex = 0
    }

    private func speakCurrentSentence() {
        guard currentSentenceIndex < sentences.count else {
            // End of chapter – advance to next
            advanceToNextSentenceOrChapter()
            return
        }

        let sentence = sentences[currentSentenceIndex]
        ttsEngine.play(text: sentence) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                self.advanceToNextSentenceOrChapter()
            }
        }
    }

    private func advanceToNextSentenceOrChapter() {
        let nextIndex = currentSentenceIndex + 1
        if nextIndex < sentences.count {
            currentSentenceIndex = nextIndex
            if isPlaying { speakCurrentSentence() }
        } else {
            // Finished chapter – try to move to the next one
            nextChapter()
        }
    }

    /// Splits a chapter's text into individual sentences for fine-grained queueing.
    private func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                sentences.append(s)
            }
        }
        return sentences.isEmpty ? [text] : sentences
    }
}
