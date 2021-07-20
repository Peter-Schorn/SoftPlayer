import SwiftUI

struct LibraryView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @State private var currentTab: String? = nil

    let animation = Animation.easeInOut(duration: 0.4)

    var body: some View {
        
        print("LibraryView.body")
        
        return PageViewController(
            pages: [
                PlaylistsScrollView()
                    .environmentObject(playerManager)
                    .environmentObject(spotify)
                    .eraseToAnyView(),
                SavedAlbumsGridView()
                    .environmentObject(playerManager)
                    .environmentObject(spotify)
                    .eraseToAnyView()
            ],
            currentPage: $playerManager.libraryPage
        )

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
