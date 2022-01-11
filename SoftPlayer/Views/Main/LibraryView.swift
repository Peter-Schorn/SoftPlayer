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
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            )
                        )
            }
        }
        .animation(animation, value: playerManager.libraryPage)
    }
    
}

struct LibraryView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        LibraryView()
            .frame(width: AppDelegate.popoverWidth, height: 350)
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
