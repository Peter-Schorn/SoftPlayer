import SwiftUI

struct LibraryView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let animation = Animation.spring(
        response: 0.3,
        dampingFraction: 0.9,
        blendDuration: 0
    )

    var body: some View {
        Group {
            switch playerManager.libraryPage {
                case .playlists:
                    PlaylistsScrollView()
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .leading),
                                removal: .move(edge: .trailing)
                            )
                        )
                case .albums:
                    SavedAlbumsGridView()
                        .transition(
                            playerManager.libraryPageTransition
                        )
                case .queue:
                    QueueView()
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            )
                        )
            }
        }
        .animation(animation, value: playerManager.libraryPage)
        .onChange(of: playerManager.libraryPage) { page in
            Loggers.firstResponder.info(
                "--- ON CHANGE OF LIBRARY PAGE TO \(page) ---"
            )
            switch page {
                case .playlists:
                    self.playerManager.queueViewIsFirstResponder = false
                    self.playerManager.savedAlbumsGridViewIsFirstResponder = false
                    self.playerManager.playlistsScrollViewIsFirstResponder = true
                case .albums:
                    self.playerManager.queueViewIsFirstResponder = false
                    self.playerManager.playlistsScrollViewIsFirstResponder = false
                    self.playerManager.savedAlbumsGridViewIsFirstResponder = true
                case .queue:
                    self.playerManager.playlistsScrollViewIsFirstResponder = false
                    self.playerManager.savedAlbumsGridViewIsFirstResponder = false
                    self.playerManager.queueViewIsFirstResponder = true
                    
            }
        }
//        .onChange(of: playerManager.isShowingLibraryView) { isShowing in
//            if !isShowing {
//                playerManager.savedAlbumsGridViewIsFirstResponder = false
//                playerManager.playlistsScrollViewIsFirstResponder = false
//            }
//        }
    }
    
}

struct LibraryView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )
    
    static var previews: some View {
        LibraryView()
            .frame(width: AppDelegate.popoverWidth, height: 350)
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
