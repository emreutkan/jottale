import Foundation

/// A parsed text chunk from an ePub, ready to be fed into the TTS engine.
struct Chapter: Identifiable {
    let id: UUID
    /// Display title for this chapter (e.g. "Chapter 1 – The Beginning").
    var title: String
    /// The clean, HTML-stripped text content ready for synthesis.
    var content: String
    /// Zero-based position of this chapter within its book.
    var index: Int

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        index: Int
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.index = index
    }
}
