import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayerView: View {

    static let animation = Animation.easeInOut(duration: 0.5)
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var namespace
    
    let albumImageId = "albumImage"
    let playingTitleId = "playingTitle"
    let playerControlsId = "playerControls"
    
    @State private var isShowingPlaylistsView = false
    
    @State private var isFirstResponder = false
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var cancellables: Set<AnyCancellable> = []

    var body: some View {
        Group {
            if isShowingPlaylistsView {
                playlistsView
            }
            else {
                playerView
            }
        }
        .overlay(NotificationView())
        .frame(
            width: AppDelegate.popoverWidth,
            height: AppDelegate.popoverHeight
        )
        .alert(isPresented: $alertIsPresented) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        }
        .background(
            KeyEventHandler(
                isFirstResponder: .constant(true),
                receiveKeyEvent: receiveKeyEvent(_:)
            )
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        .onExitCommand {
//            print("PlayerView: onExitCommand")
            if isShowingPlaylistsView {
                self.dismissPlaylistsView(animated: true)
            }
            else {
                print("not showing playlists view; dismissing popover")
                let appDelegate = NSApplication.shared.delegate as! AppDelegate
                appDelegate.popover.performClose(nil)
            }
        }
        
    }
    
    var playerView: some View {
        VStack(spacing: 5) {
            // MARK: Large Album Image
            playerManager.artworkImage
                .resizable()
                .transition(.scale)
                // MARK: Matched Geometry Effect
                .matchedGeometryEffect(
                    id: albumImageId,
                    in: namespace,
                    anchor: .center,
                    isSource: false
                )
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverWidth
                )
//                .transition(.scale)
                
//                .padding(.bottom, 5)

            // MARK: Large Playing Title
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
            .transition(.scale)
            .matchedGeometryEffect(
                id: playingTitleId, in: namespace
            )

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
                        withAnimation(Self.animation) {
                            self.isShowingPlaylistsView.toggle()
                        }
                    }, label: {
                        Image(systemName: "music.note.list")
                    })
                    .keyboardShortcut("p")
                    .help("Show playlists ⌘P")
                    Spacer()
                    AvailableDevicesButton()
                        .padding(.bottom, 2)
                }
                .padding(.top, 5)

            }
            .matchedGeometryEffect(
                id: playerControlsId, in: namespace
            )
            .padding(.horizontal, 10)

            Spacer()
        }
    }

    var playlistsView: some View {
        VStack(spacing: 0) {
            VStack {
                Button(action: {
                    self.dismissPlaylistsView(animated: true)
                }, label: {
                    Image(systemName: "chevron.down")
                        .padding(-3)
                })
                .padding(.top, 5)
                .keyboardShortcut("p")
                miniPlayerView
            }
            .padding(.horizontal, 9)
            .padding(.bottom, 9)
            .background(
                Rectangle()
                    .fill(BackgroundStyle())
                    .if(colorScheme == .dark) {
                        // make the shadow darker so it can be seen
                        // better in dark mode.
                        $0.shadow(color: .black, radius: 3, y: 2)
                    } else: {
                        $0.shadow(radius: 3, y: 2)
                    }
            )
            PlaylistsScrollView(
                isShowingPlaylistsView: $isShowingPlaylistsView
            )
        }
        .background(
            Rectangle().fill(BackgroundStyle())
        )
        .touchBar(content: PlayPlaylistsTouchBarView.init)
        .onExitCommand {
            print("playlistsView onExitCommand")
            self.dismissPlaylistsView(animated: true)
            
        }
        .onReceive(playerManager.popoverDidClose) {
            self.dismissPlaylistsView(animated: false)
        }
    }
    
    var miniPlayerView: some View {
        HStack(spacing: 0) {
            // MARK: Small Album Image
            playerManager.artworkImage
                .resizable()
                .transition(.scale)
                .matchedGeometryEffect(
                    id: albumImageId,
                    in: namespace,
                    anchor: .center,
                    isSource: true
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .cornerRadius(5)
                .shadow(radius: 2)
//                .transition(.scale)
                // MARK: Matched Geometry Effect
                
                
            VStack(spacing: 0) {
                // MARK: Small Playing Title
                VStack {
                    Text(playerManager.currentTrack?.name ?? "")
                        .fontWeight(.semibold)
                        .font(.callout)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(
                            perform: playerManager.openCurrentPlaybackInBrowser
                        )
                    Text(playerManager.albumArtistTitle)
                        .font(.footnote)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(
                            perform: playerManager.openArtistOrShowInBrowser
                        )
                }
                .transition(.scale)
                .matchedGeometryEffect(
                    id: playingTitleId, in: namespace
                )
                // MARK: Small Player Controls
                HStack(spacing: 15) {
                    ShuffleButton()
                        .scaleEffect(0.8)
                    PreviousTrackButton(size: .small)
                    PlayPauseButton()
                        .frame(width: 20, height: 20)
                    NextTrackButton(size: .small)
                    RepeatModeButton()
                        .scaleEffect(0.8)
                }
                .matchedGeometryEffect(
                    id: playerControlsId, in: namespace
                )
                .padding(.vertical, 5)
            }
            .padding(5)
            .frame(height: 70)
        }
    }

    func dismissPlaylistsView(animated: Bool) {
        if animated {
            withAnimation(Self.animation) {
                self.isShowingPlaylistsView = false
            }
        }
        else {
            self.isShowingPlaylistsView = false
        }
        self.playerManager.updatePlaylistsSortedByLastModifiedDate()
    }

    func receiveKeyEvent(_ event: NSEvent) {
        print("PlayerView key event: \(event)")
        if event.charactersIgnoringModifiers == "p" {
            withAnimation(Self.animation) {
                self.isShowingPlaylistsView = true
            }
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
