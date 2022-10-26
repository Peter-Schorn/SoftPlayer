import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayPlaylistsTouchBarView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify
    
    @State private var isPlayingPlaylist = false
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    var playlists: ArraySlice<Playlist<PlaylistItemsReference>> {

        let playlistNames = playerManager.playlists
            .map(\.name)

        Loggers.touchBarView.trace("---------------------------")
        for (index, name) in playlistNames.enumerated() {
            Loggers.touchBarView.trace("\(index + 1). '\(name)'")
        }
        Loggers.touchBarView.trace("---------------------------")
        
        var indices = 0..<0
        
        while true {
            let endIndex = playerManager.playlists.endIndex
            let minIndex = min(self.playerManager.touchbarPlaylistsOffset * 4, endIndex)
            let maxIndex = min(minIndex + 4, endIndex)
            indices = minIndex..<maxIndex
            if !indices.isEmpty || self.playerManager.touchbarPlaylistsOffset == 0 {
                break
            }
            self.playerManager.touchbarPlaylistsOffset -= 1
        }
        
        Loggers.touchBarView.trace(
            "offset: \(playerManager.touchbarPlaylistsOffset); indices: \(indices)"
        )
        return playerManager.playlists[indices]
        
//        return Playlist.spanishPlaylists[0..<4]
    }
    
    var body: some View {
        
        HStack {
            HStack {
                ForEach(
                    playlists, id: \.uri,
                    content: TouchBarPlaylistButton.init(playlist:)
                )
            }
            .frame(width: 560, alignment: .leading)
            if !playlists.isEmpty {
                navigationButtons
            }
        }
        .frame(height: 30)
    }
    
    var navigationButtons: some View {
        HStack(spacing: 2) {
            Button(action: {
                self.playerManager.touchbarPlaylistsOffset -= 1
            }, label: {
                Image(systemName: "arrowtriangle.backward.fill")
                    .padding(.horizontal, 13)
            })
            .disabled(self.playerManager.touchbarPlaylistsOffset <= 0)
            Button(action: {
                self.playerManager.touchbarPlaylistsOffset += 1
            }, label: {
                Image(systemName: "arrowtriangle.forward.fill")
                    .padding(.horizontal, 13)
            })
            .disabled(self.nextNavigationButtonIsDisabled())
        }
        .padding(.vertical, 2)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    func nextNavigationButtonIsDisabled() -> Bool {
        
        let playlistsCount = self.playerManager
                .playlists.count
        
        Loggers.touchBarView.trace(
            """
            \((playerManager.touchbarPlaylistsOffset + 1) * 4) \
            >= \(playlistsCount)
            """
        )
        return (playerManager.touchbarPlaylistsOffset + 1) * 4
                >= playlistsCount
    }
    
}

struct PlayPlaylistsTouchBarView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )

    static var previews: some View {
        PlayPlaylistsTouchBarView()
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
            .frame(width: 685, height: 30, alignment: .leading)
//            .padding(.horizontal, 5)
            // https://apple.co/3n1bdjk
        
    }
}
