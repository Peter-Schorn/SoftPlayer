import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayPlaylistsTouchBarView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify
    
    @State private var offset = 0
    
    @State private var isPlayingPlaylist = false
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    var playlists: ArraySlice<Playlist<PlaylistsItemsReference>> {

//        let playlistNames = playerManager.playlistsSortedByLastPlayedDate.map {
//            playlist in
//
//            playlist.name
//        }
//
//        for (index, playlist) in playlistNames.enumerated() {
//            print("\(index + 1). '\(playlist)'")
//        }
        
        let endIndex = playerManager.playlistsSortedByLastPlayedDate.endIndex
        let minIndex = self.offset * 4
        let maxIndex = min(minIndex + 4, endIndex)
        let indices = minIndex..<maxIndex
//        print("offset: \(offset); indices: \(indices)")
        return playerManager.playlistsSortedByLastPlayedDate[indices]
    }
    
    var body: some View {
        
        HStack {
            
            HStack {
                ForEach(
                    playlists, id: \.uri,
                    content: TouchBarPlaylistButton.init(playlist:)
                )
            }
            .frame(width: 562, alignment: .leading)
            
            navigationButtons
        }
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .offset(y: 2)
        .onDisappear {
            self.offset = 0
        }
        
    }
    
    var navigationButtons: some View {
        HStack {
            Button(action: {
                self.offset -= 1
            }, label: {
                Image(systemName: "arrowtriangle.backward.fill")
                    .padding(.horizontal, 10)
            })
            .disabled(self.offset <= 0)
            Button(action: {
                self.offset += 1
            }, label: {
                Image(systemName: "arrowtriangle.forward.fill")
                    .padding(.horizontal, 10)
            })
            .disabled(self.nextNavigationButtonIsDisabled())
        }
        .padding(2)
        .cornerRadius(5)
        .shadow(radius: 5)
    }
    
    func nextNavigationButtonIsDisabled() -> Bool {
        
        let playlistsCount = self.playerManager
                .playlistsSortedByLastPlayedDate.count
        
//        print("\(offset * 4) >= \(playlistsCount + 4)")
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
