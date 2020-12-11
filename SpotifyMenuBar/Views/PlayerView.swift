import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayerView: View {

    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var isShowingPlaylistsView = false
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // MARK: Cancellables
    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        Group {
            
            if isShowingPlaylistsView {
                PlaylistsView(isPresented: $isShowingPlaylistsView)
            }
            else {
                playerView
            }
        }
        .overlay(NotificationView())
        .background(
            FocusView(
                isFirstResponder: Binding(
                    get: { !isShowingPlaylistsView },
                    set: { _ in }
                )
            )
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
//        .onKeyEvent { event in
//            print("PlayerView key event: \(event)")
////            if event.charactersIgnoringModifiers == "p" {
////            }
//        }
        .onExitCommand {
            print("PlayerView: onExitCommand")
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            appDelegate.popover.performClose(nil)
        }
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
    
    var playerView: some View {
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
                    .onTapGesture(
                        perform: playerManager.openCurrentPlaybackInBrowser
                    )

                Text(playerManager.albumArtistTitle)
                    .lineLimit(1)
                    .foregroundColor(Color.primary.opacity(0.9))
                    .onTapGesture(
                        perform: playerManager.openArtistOrShowInBrowser
                    )
            }
            .padding(.horizontal, 10)
            .frame(height: 60)

            // MARK: Main Player Controls
            VStack(spacing: 0) {

                PlaybackPositionView()

                HStack(spacing: 15) {

                    ShuffleButton()
                        .padding(.top, 2)
                    PreviousTrackButton(size: .large)
                    PlayPauseButton()
                        .frame(width: 38, height: 38)
                    NextTrackButton(size: .large)
                    RepeatModeButton()
                        .padding(.top, 2)

                }
                .font(.largeTitle)

                SoundVolumeSlider()
                    .frame(height: 30)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 5)

                HStack {
                    Button(action: {
                        withAnimation(PlaylistsView.animation) {
                            self.isShowingPlaylistsView.toggle()
                        }
                    }, label: {
                        Image(systemName: "music.note.list")
                    })
                    .keyboardShortcut("p")
                    .help("Show playlists")

                    Spacer()
                    AvailableDevicesButton()
                        .padding(.bottom, 2)
                }
                .padding(.top, 5)

            }
            .padding(.horizontal, 10)

            Spacer()
        }
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
