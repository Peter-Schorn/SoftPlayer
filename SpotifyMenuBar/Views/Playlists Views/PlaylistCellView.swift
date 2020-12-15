import SwiftUI
import Combine
import SpotifyWebAPI

struct PlaylistCellView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let playlist: Playlist<PlaylistsItemsReference>

    let isSelected: Bool
    
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
    
    var playlistOwnedByCurrentUser: Bool {
        if let userId = self.playlist.owner?.id {
            return self.playerManager.currentUser?.id == userId
        }
        return false
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
            
            if playlistOwnedByCurrentUser {
                Button(action: {
                    self.addCurrentItemToPlaylist()
                }, label: {
                    Image(systemName: "text.badge.plus")
                })
                .buttonStyle(PlainButtonStyle())
                .help(addToPlaylistTooltip)
            }
            
        }
        .disabled(isSelected)
        .padding(.leading, 8)
        .padding(.trailing, 15)
//        .padding(.trailing, 5)
        
    }
    
    /// Adds the currently playing track/episode to a playlist.
    func addCurrentItemToPlaylist() {
        
        guard let currentItemURI = playerManager.currentTrack?.id?(),
                !currentItemURI.isEmpty else {
            Loggers.playlistCellView.error(
                "PlaylistsView: no URI for the currently playing item"
            )
            self.playerManager.presentNotification(
                title: "Couldn't retrieve the currently playing " +
                       "track or episode",
                message: ""
            )
            return
        }
        
        self.playerManager.playlistsLastModifiedDates[playlist.uri] = Date()
        
        let itemName = playerManager.currentTrack?.name ?? "nil"
        Loggers.playlistCellView.notice(
            "adding '\(itemName)' to '\(playlist.name)'"
        )
        self.spotify.api.addToPlaylist(
            playlist.uri, uris: [currentItemURI]
        )
        .receive(on: RunLoop.main)
        .sink(
            receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        let messageTitle = #"Added "\#(itemName)" "# +
                            #"to "\#(playlist.name)""#
                        self.playerManager.presentNotification(
                            title: messageTitle,
                            message: ""
                        )
                    case .failure(let error):
                        let alertTitle = #"Couldn't add "\#(itemName)" "# +
                            #"to "\#(playlist.name)""#
                        self.playerManager.presentNotification(
                            title: alertTitle,
                            message: error.localizedDescription
                        )
                        Loggers.playlistCellView.error(
                            "\(alertTitle): \(error)"
                        )
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
                    let alertTitle = #"Couldn't play "\#(playlist.name)""#
                    self.playerManager.presentNotification(
                        title: alertTitle,
                        message: error.localizedDescription
                    )
                    Loggers.playlistCellView.error(
                        "\(alertTitle): \(error)"
                    )
                }
            })
        
    }

}

struct PlaylistCellView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
            .onAppear {
                PlayerView.debugIsShowingPlaylistsView = true
            }
    }
}
