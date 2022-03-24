import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct TouchBarPlaylistButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify
    
    let playlist: Playlist<PlaylistItemsReference>

    init(playlist: Playlist<PlaylistItemsReference>) {
        self.playlist = playlist
    }
    
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var playPlaylistCancellable: AnyCancellable? = nil
    
    @ViewBuilder var playlistImage: some View {

        if self.playlist.uri.isSavedTracksURI {
            SavedTracksImage()
        }
        else if let identifier = try? SpotifyIdentifier(uri: self.playlist.uri),
                let image = self.playerManager.image(for: identifier) {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        else {
            Image(.spotifyAlbumPlaceholder)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
        
    }
    
    var body: some View {
        
        Button(action: playPlaylist, label: {
            playlistImage
                .colorMultiply(Color(#colorLiteral(red: 0.4762042937, green: 0.4762042937, blue: 0.4762042937, alpha: 1)))
                .blur(radius: 2)
                .frame(width: 133, height: 28)
                .cornerRadius(3)
                .overlay(
                    Text(playlist.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .padding(.horizontal, 5)
                        .fixedSize(horizontal: false, vertical: true)
                )
        })
        .buttonStyle(PlainButtonStyle())

    }
    
    func playPlaylist() {
        
        self.playPlaylistCancellable = self.playerManager
            .playPlaylist(self.playlist)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let alert) = completion {
                        self.playerManager.notificationSubject.send(alert)
                    }
                },
                receiveValue: { }
            )

    }

}

struct TouchBarPlaylistButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayPlaylistsTouchBarView_Previews.previews
    }
}
