import XCTest
@testable import SoulReaderCore

final class BookModelTests: XCTestCase {

    // MARK: - Book

    func testBookDefaultValues() {
        let book = Book(title: "Test Title", author: "Test Author", filePath: "test.epub")
        XCTAssertFalse(book.id.uuidString.isEmpty)
        XCTAssertEqual(book.title, "Test Title")
        XCTAssertEqual(book.author, "Test Author")
        XCTAssertNil(book.coverImagePath)
        XCTAssertEqual(book.filePath, "test.epub")
    }

    func testBookCodableRoundTrip() throws {
        let original = Book(
            title: "Roundtrip",
            author: "Author Name",
            coverImagePath: "/covers/book.jpg",
            filePath: "roundtrip.epub"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Book.self, from: data)
        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.title, decoded.title)
        XCTAssertEqual(original.author, decoded.author)
        XCTAssertEqual(original.coverImagePath, decoded.coverImagePath)
        XCTAssertEqual(original.filePath, decoded.filePath)
    }

    // MARK: - Chapter

    func testChapterDefaults() {
        let chapter = Chapter(title: "Ch 1", content: "Hello world.", index: 0)
        XCTAssertFalse(chapter.id.uuidString.isEmpty)
        XCTAssertEqual(chapter.title, "Ch 1")
        XCTAssertEqual(chapter.content, "Hello world.")
        XCTAssertEqual(chapter.index, 0)
    }

    // MARK: - PlaybackState

    func testPlaybackStateEquality() {
        XCTAssertEqual(PlaybackState.stopped, .stopped)
        XCTAssertEqual(PlaybackState.playing, .playing)
        XCTAssertEqual(PlaybackState.buffering, .buffering)
        XCTAssertEqual(PlaybackState.paused(sentenceIndex: 3), .paused(sentenceIndex: 3))
        XCTAssertNotEqual(PlaybackState.paused(sentenceIndex: 1), .paused(sentenceIndex: 2))
        XCTAssertNotEqual(PlaybackState.playing, .stopped)
    }
}
