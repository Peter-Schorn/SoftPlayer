import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct AlbumGridItemView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    let album: Album
    let isSelected: Bool

    var albumImage: Image {
        
        if let uri = album.uri,
                let identifier = try? SpotifyIdentifier(uri: uri),
                let image = self.playerManager.image(for: identifier) {
            return image
        }

        return Image(.spotifyAlbumPlaceholder)
        
    }
    
    var isCurrentlyPlaying: Bool {
        self.album.uri ==
                self.playerManager.currentlyPlayingContext?.context?.uri
    }

    var body: some View {
        Button(action: {
            playerManager.playAlbum(album)
        }, label: {
            VStack {
                albumImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(5)
                HStack {
                    Text(album.name)
                        .font(.subheadline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if isCurrentlyPlaying {
                        NowPlayingAnimation(
                            isAnimating: $playerManager.isPlaying
                        )
                            .frame(width: 12, height: 10)
                    }
                }
                Spacer()
            }
        })
        .disabled(isSelected)
        .buttonStyle(PlainButtonStyle())
        .padding(2)
    }
    
}

struct AlbumGridItemView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        AlbumGridItemView(
            album: .darkSideOfTheMoon,
            isSelected: false
        )
        .environmentObject(playerManager)
        .environmentObject(playerManager.spotify)
        .frame(width: 80, height: 80)
    }
}
