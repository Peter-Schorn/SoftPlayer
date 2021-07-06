import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import SpotifyExampleContent
import Logging

struct SavedAlbumsGridView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    let albums: [Album] = [
        .abbeyRoad,
        .darkSideOfTheMoon,
        .inRainbows,
        .jinx,
        .meddle,
        .skiptracing
    ]

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns) {
                ForEach(albums, id: \.id) { album in
                    AlbumGridItemView(album: album)
                }
            }
        }
    }
}

struct SavedAlbumsGridView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SavedAlbumsGridView()
            .frame(width: AppDelegate.popoverWidth, height: 320)
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
