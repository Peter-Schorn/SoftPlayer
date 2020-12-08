import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayerView: View {

    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var cancellables: Set<AnyCancellable> = []

    var albumArtistTitle: String? {
        if let artistName = playerManager.currentTrack?.artist {
            if let albumName = playerManager.currentTrack?.album {
                return "\(artistName) - \(albumName)"
            }
            return artistName
        }
        if let albumName = playerManager.currentTrack?.album {
            return albumName
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 5) {
            playerManager.artworkImage
                .resizable()
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverWidth
                )
                .padding(.bottom, 5)
            
            VStack(spacing: 5) {
                Text(playerManager.currentTrack?.name ?? "")
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(albumArtistTitle ?? "")
                    .lineLimit(1)
                    .foregroundColor(Color.primary.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .frame(height: 60)
            
            // MARK: Player Controls
            VStack(spacing: 0) {
                
                PlaybackPositionView()
                
                HStack(spacing: 15) {
                    
                    ShuffleButton()
                        .padding(.top, 2)
                    PreviousTrackButton()
                    PlayPauseButton()
                        .frame(width: 38, height: 38)
                    NextTrackButton()
                    RepeatButton()
                        .padding(.top, 2)
                    
                }
                .font(.largeTitle)
                
                SoundVolumeSlider()
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 5)
                
                HStack {
                    AddToPlaylistButton()
                    Spacer()
                    AvailableDevicesButton()
                        .scaleEffect(1.2)
                        .padding(.bottom, 2)
                }
                .padding(.top, 5)
                    
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
        .overlay(NotificationView())
        .touchBar(content: PlayPlaylistsTouchBarView.init)
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .frame(
            width: AppDelegate.popoverWidth,
            height: AppDelegate.popoverHeight
        )
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
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                )
                .preferredColorScheme(colorScheme)
                .onAppear(perform: onAppear)
        }
    }
    
    static func onAppear() {
        
    }
}
