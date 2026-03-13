import Foundation
import Combine

/// Manages the user's book collection, persisting it to disk via JSON.
///
/// Responsibilities:
/// - Import new ePubs by delegating to ``ePubParserService``
/// - Persist the ``Book`` catalogue between launches
/// - Provide parsed ``Chapter`` arrays on demand
final class LibraryController: ObservableObject {

    // MARK: - Published State

    @Published private(set) var books: [Book] = []

    // MARK: - Private

    private let parser = ePubParserService()
    private var chapterCache: [UUID: [Chapter]] = [:]

    private var catalogueURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("catalogue.json")
    }

    // MARK: - Init

    init() {
        loadCatalogue()
    }

    // MARK: - Public API

    /// Imports an ePub from the given URL, parses it, and adds it to the library.
    func importBook(from url: URL) {
        // Ensure we hold access while copying
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let (book, chapters) = try parser.parse(ePubAt: url)
            chapterCache[book.id] = chapters
            books.append(book)
            saveCatalogue()
        } catch {
            print("[LibraryController] Failed to import book: \(error.localizedDescription)")
        }
    }

    /// Returns parsed chapters for a book, loading from cache or re-parsing if needed.
    func chapters(for book: Book) -> [Chapter] {
        if let cached = chapterCache[book.id] {
            return cached
        }

        // Re-parse from disk if cache was evicted (e.g. after app restart)
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(book.filePath)

        do {
            let (_, chapters) = try parser.parse(ePubAt: fileURL)
            chapterCache[book.id] = chapters
            return chapters
        } catch {
            print("[LibraryController] Failed to load chapters: \(error.localizedDescription)")
            return []
        }
    }

    /// Removes books at the given index-set offsets.
    func removeBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        saveCatalogue()
    }

    // MARK: - Persistence

    private func saveCatalogue() {
        do {
            let data = try JSONEncoder().encode(books)
            try data.write(to: catalogueURL, options: .atomic)
        } catch {
            print("[LibraryController] Failed to save catalogue: \(error.localizedDescription)")
        }
    }

    private func loadCatalogue() {
        guard FileManager.default.fileExists(atPath: catalogueURL.path) else { return }
        do {
            let data = try Data(contentsOf: catalogueURL)
            books = try JSONDecoder().decode([Book].self, from: data)
        } catch {
            print("[LibraryController] Failed to load catalogue: \(error.localizedDescription)")
        }
    }
}
