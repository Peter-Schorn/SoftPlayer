import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayPlaylistsTouchBarView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify
    
    @State private var offset = 0
    
    @State private var isPlayingPlaylist = false
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    var playlists: ArraySlice<Playlist<PlaylistItemsReference>> {

        let playlistNames = playerManager.playlistsSortedByLastModifiedDate
            .map(\.name)

        for (index, playlist) in playlistNames.enumerated() {
            Loggers.touchBarView.trace("\(index + 1). '\(playlist)'")
        }
        
        let endIndex = playerManager.playlistsSortedByLastModifiedDate.endIndex
        let minIndex = self.offset * 4
        let maxIndex = min(minIndex + 4, endIndex)
        let indices = minIndex..<maxIndex
        Loggers.touchBarView.trace(
            "offset: \(offset); indices: \(indices)"
        )
        return playerManager.playlistsSortedByLastModifiedDate[indices]
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
        .offset(y: 2)
        .onDisappear {
            self.offset = 0
        }
        .frame(height: 30)
    }
    
    var navigationButtons: some View {
        HStack(spacing: 2) {
            Button(action: {
                self.offset -= 1
            }, label: {
                Image(systemName: "arrowtriangle.backward.fill")
                    .padding(.horizontal, 13)
            })
            .disabled(self.offset <= 0)
            Button(action: {
                self.offset += 1
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
                .playlistsSortedByLastModifiedDate.count
        
        Loggers.touchBarView.trace("\((offset + 1) * 4) >= \(playlistsCount)")
        return (offset + 1) * 4 >= playlistsCount
    }
    
}

struct PlayPlaylistsTouchBarView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    static let playerManager = PlayerManager(spotify: spotify)

    static var previews: some View {
        PlayPlaylistsTouchBarView()
            .environmentObject(spotify)
            .environmentObject(playerManager)
            .frame(width: 685, height: 30, alignment: .leading)
//            .padding(.horizontal, 5)
            // https://apple.co/3n1bdjk
        
    }
}
