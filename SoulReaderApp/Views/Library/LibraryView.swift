import SwiftUI

/// Main library screen – shows all imported books in a two-column grid.
struct LibraryView: View {
    @EnvironmentObject var libraryController: LibraryController
    @EnvironmentObject var playbackController: PlaybackController

    /// Controls the file-importer sheet.
    @State private var isImporting = false

    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(libraryController.books) { book in
                            BookCellView(book: book)
                                .onTapGesture {
                                    playbackController.load(book: book,
                                                            chapters: libraryController.chapters(for: book))
                                }
                        }
                    }
                    .padding()
                    // Extra bottom padding so the mini-player doesn't cover the last row.
                    .padding(.bottom, 80)
                }

                // Sticky mini-player shown whenever audio is loaded.
                if playbackController.currentBook != nil {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import Book", systemImage: "plus")
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.epub],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        libraryController.importBook(from: url)
                    }
                case .failure(let error):
                    print("[LibraryView] Import failed: \(error.localizedDescription)")
                }
            }
            .animation(.easeInOut, value: playbackController.currentBook?.id)
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .environmentObject(LibraryController())
        .environmentObject(PlaybackController())
}
