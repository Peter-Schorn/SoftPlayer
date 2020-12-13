import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI

struct PlayerView: View {

    static let animation = Animation.easeInOut(duration: 0.6)
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var namespace
    
    @State private var isShowingPlaylistsView = false
    @State private var isShowingPlaylistsScrollView = false
    
    @State private var isFirstResponder = false
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var cancellables: Set<AnyCancellable> = []

    // MARK: Geometry Effect Constants
    
    var playerViewIsSource: Bool {
        !isShowingPlaylistsView
    }
    
    var playlistsViewIsSource: Bool {
        !isShowingPlaylistsView
    }
    
    let albumImageId = "albumImage"
    let trackEpisodeNameId = "trackEpisodeTitle"
    let albumArtisTitleId = "albumArtistTitle"

    let shuffleButtonId = "shuffleButton"
    let previousTrackButtonId = "previousTrack"
    let playPauseButtonId = "playPauseButton"
    let nextTrackButtonId = "nextTrack"
    let repeatModeButtonId = "repeatModeButton"

    // MARK: - Begin Views -
    
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
            KeyEventHandler(receiveKeyEvent: receiveKeyEvent(_:))
                .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        .onExitCommand {
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
                // MARK: Matched Geometry Effect
                .transition(.scale)
                .matchedGeometryEffect(
                    id: albumImageId,
                    in: namespace,
                    anchor: .center,
                    isSource: playerViewIsSource
                )
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverWidth
                )
                .padding(.bottom, 5)

            // MARK: Large Playing Title
            VStack(spacing: 5) {
                Text(playerManager.currentTrack?.name ?? "")
                    .fontWeight(.semibold)
                    // MARK: Matched Geometry Effect
                    .matchedGeometryEffect(
                        id: trackEpisodeNameId,
                        in: namespace,
                        isSource: playerViewIsSource
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .onTapGesture(
                        perform: playerManager.openCurrentPlaybackInBrowser
                    )

                Text(playerManager.albumArtistTitle)
                    // MARK: Matched Geometry Effect
                    .matchedGeometryEffect(
                        id: albumArtisTitleId,
                        in: namespace,
                        isSource: playerViewIsSource
                    )
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
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: shuffleButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .padding(.top, 2)
                    PreviousTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: previousTrackButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                    PlayPauseButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playPauseButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .frame(width: 38, height: 38)
                    NextTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: nextTrackButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                    RepeatModeButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: repeatModeButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
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
                    .shadow(
                        color: colorScheme == .dark ? .black : .defaultShadow,
                        radius: 3,
                        y: 2
                    )
            )
            PlaylistsScrollView(
                isShowingPlaylistsView: $isShowingPlaylistsView
            )
        }
        .background(
            Rectangle().fill(BackgroundStyle())
        )
        // MARK: Playlists View Transition
        .transition(.move(edge: .bottom))
//        .transition(
//            .asymmetric(
//                insertion: .move(edge: .bottom),
//                removal: .opacity
//            )
//        )
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
                .cornerRadius(5)
                // MARK: Matched Geometry Effect
                .matchedGeometryEffect(
                    id: albumImageId,
                    in: namespace,
                    anchor: .center,
                    isSource: playlistsViewIsSource
                )
//                .transaction { transaction in
//                    transaction.disablesAnimations = true
//                }
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .shadow(
                    color: colorScheme == .dark ? .black : .defaultShadow,
                    radius: 2
                )
                
            VStack(spacing: 0) {
                // MARK: Small Playing Title
                VStack {
                    Text(playerManager.currentTrack?.name ?? "")
                        .fontWeight(.semibold)
                        .font(.callout)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: trackEpisodeNameId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(
                            perform: playerManager.openCurrentPlaybackInBrowser
                        )
                    Text(playerManager.albumArtistTitle)
                        .font(.footnote)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: albumArtisTitleId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(
                            perform: playerManager.openArtistOrShowInBrowser
                        )
                }
                // MARK: Small Player Controls
                HStack(spacing: 15) {
                    ShuffleButton()
                        .scaleEffect(0.8)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: shuffleButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                    PreviousTrackButton(size: .small)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: previousTrackButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                    PlayPauseButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playPauseButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .frame(width: 20, height: 20)
                    NextTrackButton(size: .small)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: nextTrackButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                    RepeatModeButton()
                        .scaleEffect(0.8)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: repeatModeButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                }
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
        self.playerManager.retrieveAvailableDevices()
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
