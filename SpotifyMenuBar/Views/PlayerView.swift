import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayerView: View {

    fileprivate static var debugIsShowingNotification = false
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var cancellables: Set<AnyCancellable> = []

    @State private var isShowingNotification = false
    @State fileprivate var notificationMessage = ""
//        "Evolution is the unifying theory of the life sciences"
    
    /// The currently playing track.
    var track: SpotifyTrack? { playerManager.currentTrack }
    
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
                Text(track?.name ?? "")
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
                    AvailableDevicesView()
                        .scaleEffect(1.2)
                        .padding(.bottom, 2)
                }
                .padding(.top, 5)
                    
            }
            .padding(.horizontal, 10)
            
            Spacer()
        }
        .overlay(notificationView)
        .frame(
            width: AppDelegate.popoverWidth,
            height: AppDelegate.popoverHeight
        )
        .onReceive(playerManager.alertSubject) { message in
            self.notificationMessage = message
            withAnimation() {
                self.isShowingNotification = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation() {
                    self.isShowingNotification = false
                }
            }
        }
    }
    
    var notificationView: some View {
        VStack {
            if isShowingNotification || Self.debugIsShowingNotification {
                Text(notificationMessage)
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                    .padding(5)
//                    .background(Color.gray.blur(radius: 5).opacity(0.8))
                    .background(
                        VisualEffectView(
                            material: .popover,
                            blendingMode: .withinWindow
                        )
                    )
                    .cornerRadius(5)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .shadow(radius: 5)
                    .transition(.move(edge: .top))
            }
            Spacer()
        }
    }
    
    func playPlaylist(_ playlist: Playlist<PlaylistsItemsReference>) {
        
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist),
            offset: nil
        )
        
        self.spotify.api.play(playbackRequest)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Couldn't play '\(playlist.name)': \(error)")
                    }
                },
                receiveValue: { }
            )
            .store(in: &cancellables)

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
//        PlayerView.debugIsShowingNotification = true
    }
}
