import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct PlaylistCellView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let playlist: Playlist<PlaylistItemsReference>

    let isSelected: Bool
    
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    @State private var cancellables: Set<AnyCancellable> = []

    init(
        playlist: Playlist<PlaylistItemsReference>,
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
    
    var isCurrentlyPlaying: Bool {
        self.playlist.uri ==
                self.playerManager.currentlyPlayingContext?.context?.uri
    }
    
    var body: some View {
        HStack {
            
            Button(action: playPlaylist, label: {
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
                    
                    if isCurrentlyPlaying {
                        NowPlayingAnimation(
                            isAnimating: $playerManager.isPlaying
                        )
                        .frame(width: 12, height: 10)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onDragOptional {
                    if let url = try? SpotifyIdentifier(uri: self.playlist).url {
                        return NSItemProvider(object: url as NSURL)
                    }
                    return nil
                }
            })
            .buttonStyle(PlainButtonStyle())
            
            if playlistOwnedByCurrentUser {
                Button(action: {
                    self.playerManager.addCurrentItemToPlaylist(
                        playlist: self.playlist
                    )
                }, label: {
                    Image(systemName: "text.badge.plus")
                })
                .buttonStyle(PlainButtonStyle())
                .help(Text(
                    """
                    Add the currently playing track or episode to this playlist
                    """
                ))
            }
            
        }
        .disabled(isSelected)
        .padding(.leading, 8)
        .padding(.trailing, 15)
        .contentShape(Rectangle())
        .contextMenu(menuItems: contextMenu)
        
    }
    
    func contextMenu() -> some View {
        HStack {
            Button("Open in Spotify") {
                guard let url = URL(string: self.playlist.uri) else {
                    NSSound.beep()
                    return
                }
                self.playerManager.openSpotifyDesktopApplication { _, _ in
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Unfollow Playlist") {
                self.playerManager.unfollowPlaylist(self.playlist)
            }
            
        }
    }

    func playPlaylist() {
        
        self.playPlaylistCancellable = self.playerManager
            .playPlaylist(self.playlist)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        self.playerManager.retrieveCurrentlyPlayingContext()
                    case .failure(let alert):
                        self.playerManager.notificationSubject.send(alert)
                }
            })
        
    }

}

struct PlaylistCellView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        
//        Self.withAllColorSchemes {
        LazyVStack {
            PlaylistCellView(playlist: .menITrust, isSelected: false)
                .environmentObject(playerManager.spotify)
                .environmentObject(playerManager)
        }
        .frame(width: AppDelegate.popoverWidth, height: 100)
//        }

//        PlayerView_Previews.previews
//            .onAppear {
//                PlayerView.debugIsShowingLibraryView = true
//            }
    }
}
