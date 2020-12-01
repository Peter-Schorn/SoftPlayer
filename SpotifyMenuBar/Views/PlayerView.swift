import Foundation
import Combine
import SwiftUI

struct PlayerView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    /// The currently playing track.
    var track: SpotifyTrack? { playerManager.currentTrack }
    
    var body: some View {
        VStack(spacing: 5) {
            playerManager.artworkImage
                .resizable()
                .frame(
                    width: CGFloat(AppDelegate.popoverWidth),
                    height: CGFloat(AppDelegate.popoverWidth)
                )
                .padding(.bottom, 5)
            
            VStack(spacing: 5) {
                Text(track?.name ?? "")
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(albumArtistTitle ?? "")
                    .lineLimit(1)
                    .foregroundColor(Color.primary.opacity(0.9))
            }
            .padding(.horizontal, 8)
            .frame(height: 60)
            
            PlayerControlsView()
            Spacer()
        }
        .frame(
            width: CGFloat(AppDelegate.popoverWidth),
            height: CGFloat(AppDelegate.popoverHeight)
        )
    }
    
    var albumArtistTitle: String? {
        if let artistName = track?.artist {
            if let albumName = track?.album {
                return "\(artistName) - \(albumName)"
            }
            return artistName
        }
        if let albumName = track?.album {
            return albumName
        }
        return nil
    }
    
}

struct PlayerView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            PlayerView()
                .environmentObject(playerManager.spotify)
                .environmentObject(playerManager)
                .frame(
                    width: CGFloat(AppDelegate.popoverWidth),
                    height: CGFloat(AppDelegate.popoverHeight)
                )
                .preferredColorScheme(colorScheme)
        }
    }
}
