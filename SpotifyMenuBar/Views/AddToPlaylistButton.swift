import SwiftUI
import Combine
import SpotifyWebAPI

struct AddToPlaylistButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertIsPresented = false
    
    @State private var cancellables: [AnyCancellable] = []

    var body: some View {
        Menu {
            ForEach(
                playerManager.currentUserPlaylists, id: \.uri
            ) { playlist in
                Button(playlist.name) {
                    self.addCurrentItemToPlaylist(playlist)
                }
            }
        } label: {
            HStack {
                Image(systemName: "music.note.list")
            }
        }
        .frame(width: 50)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }

    }
    
    /// Adds the currently playing track/episode to a playlist.
    func addCurrentItemToPlaylist(
        _ playlist: Playlist<PlaylistsItemsReference>
    ) {
        guard let currentItemURI = playerManager.currentTrack?.id?() else {
            print(
                "AddToPlaylistButton: no URI for the currently playing item"
            )
            return
        }
        
        let itemName = playerManager.currentTrack?.name ?? "unknown"
        
        self.spotify.api.addToPlaylist(
            playlist.uri, uris: [currentItemURI]
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        let message = #"Added "\#(itemName)" "# +
                            #"to "\#(playlist.name)""#
                        self.playerManager.alertSubject.send(message)
                    case .failure(let error):
                        self.alertTitle = #"Couldn't add "\#(itemName)" "# +
                            #"to "\#(playlist.name)""#
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                        print("\(alertTitle): \(error)")
                }
            },
            receiveValue: { _ in }
        )
        .store(in: &cancellables)
        
        
    }

}

struct AddToPlaylistButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
