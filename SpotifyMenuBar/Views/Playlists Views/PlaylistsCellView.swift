import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistsCellView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let playlist: Playlist<PlaylistsItemsReference>

    let isSelected: Bool
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []

    let addToPlaylistTooltip = "Add the currently playing track or " +
        "episode to this playlist"

    init(
        playlist: Playlist<PlaylistsItemsReference>,
        isSelected: Bool
    ) {
        self.playlist = playlist
        self.isSelected = isSelected
    }
    
    var playlistImage: Image {
        
        if let identifier = try? SpotifyIdentifier(uri: playlist.uri),
                let image = self.playerManager.image(for: identifier) {
            return image
        }
        return Image(.spotifyAlbumPlaceholder)
    }
    
    var body: some View {
        HStack {
            Button(action: {
                self.playPlaylist()
            }, label: {
                HStack {
                    playlistImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(2)
                    Text(playlist.name)
                        .font(.subheadline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(PlainButtonStyle())
            if playerManager.currentUserPlaylists.contains(playlist) {
                Button(action: {
                    self.addCurrentItemToPlaylist()
                }, label: {
                    Image(systemName: "text.badge.plus")
                })
                .help(addToPlaylistTooltip)
            }
        }
        .disabled(isSelected)
        .padding(.horizontal, 10)
    }
    
    /// Adds the currently playing track/episode to a playlist.
    func addCurrentItemToPlaylist() {
        
        guard let currentItemURI = playerManager.currentTrack?.id?() else {
            print(
                "PlaylistsView: no URI for the currently playing item"
            )
            return
        }
        
        self.playerManager.playlistsLastAddedDates[playlist.uri] = Date()
        
        let itemName = playerManager.currentTrack?.name ?? "unknown"
        print("adding \(itemName) to \(playlist.name)")
        
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

    func playPlaylist() {
        
        self.playPlaylistCancellable = self.playerManager
            .playPlaylist(playlist)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.alertTitle =
                        #"Couldn't play "\#(playlist.name)""#
                    self.alertMessage = error.localizedDescription
                    self.alertIsPresented = true
                    print("\(alertTitle): \(error)")
                }
            })
        
    }

}

struct PlaylistsCellView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsView_Previews.previews
    }
}
