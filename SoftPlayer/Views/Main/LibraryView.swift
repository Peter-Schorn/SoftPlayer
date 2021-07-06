import SwiftUI

struct LibraryView: View {
    
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            
            PlaylistsScrollView()
                .tabItem {
                    Image(systemName: "music.note.list")
                }
                .tag(0)
            
            SavedAlbumsGridView()
                .tabItem {
                    Image(systemName: "square.stack")
                }
                .tag(1)
            
        }
        

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
