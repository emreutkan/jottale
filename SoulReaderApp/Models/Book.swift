import Foundation
import SwiftUI

/// Represents an imported ePub book in the library.
struct Book: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    /// Relative file path to the stored cover image, if available.
    var coverImagePath: String?
    /// Relative file path to the imported ePub source file.
    var filePath: String
    /// Date the book was added to the library.
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String,
        coverImagePath: String? = nil,
        filePath: String,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImagePath = coverImagePath
        self.filePath = filePath
        self.dateAdded = dateAdded
    }
}
