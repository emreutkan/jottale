import SwiftUI

@main
struct SoulReaderApp: App {
    // MARK: - Dependencies (injected at root level)
    @StateObject private var libraryController = LibraryController()
    @StateObject private var playbackController = PlaybackController()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(libraryController)
                .environmentObject(playbackController)
        }
    }
}
