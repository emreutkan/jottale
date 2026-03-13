import SwiftUI

/// Displays a single book cover and title in the library grid.
struct BookCellView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            coverImage
                .frame(maxWidth: .infinity)
                .aspectRatio(2/3, contentMode: .fill)
                .clipped()
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

            Text(book.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .foregroundColor(.primary)

            Text(book.author)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(4)
    }

    // MARK: - Cover Image

    @ViewBuilder
    private var coverImage: some View {
        if let coverPath = book.coverImagePath,
           let uiImage = UIImage(contentsOfFile: coverPath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // Placeholder cover
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.indigo.opacity(0.7), .purple.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                    Text(book.title)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 6)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleBook = Book(title: "The Great Journey", author: "Jane Doe", filePath: "sample.epub")
    return BookCellView(book: sampleBook)
        .frame(width: 160)
        .padding()
}
