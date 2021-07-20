import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Logging

struct SavedAlbumsGridView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var searchText = ""
    @State private var searchFieldIsFocused = false
    
    @State private var loadAlbumsCancellable: AnyCancellable? = nil

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var searchBar: some View {
        FocusableTextField(
            text: $searchText,
            isFirstResponder: $searchFieldIsFocused,
            onCommit: searchFieldDidCommit,
            receiveKeyEvent: { _ in true }
        )
        .touchBar(content: PlayPlaylistsTouchBarView.init)
        .padding(5)
    }

    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                searchBar
                    .padding(.bottom, -10)
                LazyVGrid(columns: columns, spacing: nil) {
                    ForEach(
                        Array(playerManager.savedAlbums.enumerated()),
                        id: \.element.id
                    ) { offset, album in
                        AlbumGridItemView(album: album)
                            .if((0...3).contains(offset)) {
                                $0.padding(.top, 7)
                            }
                            .id(offset)
                    }
                }
                .padding(.horizontal, 5)
                
            }
            .onAppear {
                if !self.playerManager.didScrollToAlbumsSearchBar {
                    scrollView.scrollTo(0, anchor: .top)
                    self.playerManager.didScrollToAlbumsSearchBar = true
                }
            }
        }
    }
    
    func searchFieldDidCommit() {
        
    }

}

struct SavedAlbumsGridView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SavedAlbumsGridView()
            .frame(width: AppDelegate.popoverWidth, height: 320)
            .onAppear {
                playerManager.retrieveSavedAlbums()
            }
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
            
    }
}
