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
            
            // MARK: Player Controls
            VStack(spacing: 0) {
                
                PlaybackPositionView()
                    .padding(.horizontal, 10)
                
                // MARK: - Main Player Controls -
                HStack(spacing: 17) {
                    
                    // MARK: Shuffle
                    ShuffleButton()
                        .padding(.bottom, 1)

                    PreviousTrackButton()

                    // MARK: Play/Pause
                    PlayPauseButton()
                        .frame(width: 40, height: 40)

                    NextTrackButton()
                    
                    // MARK: Repeat Mode
                    RepeatButton()
                        .padding(.trailing, 1)
                    
                    // MARK: Available Devices
    //                AvailableDevicesView()
    //                    .scaleEffect(1.2)
    //                    .padding(.bottom, 2)
    //                    .disabled(!allowedActions.contains(.transferPlayback))
                    
                }
                .font(.largeTitle)
                .padding(.horizontal, 10)
                
                // MARK: Sound Volume
                SoundVolumeSlider()
                    .padding(.horizontal, 15)
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 5)
            }
            
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
