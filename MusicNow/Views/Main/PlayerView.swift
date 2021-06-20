import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct PlayerView: View {

    static var debugIsShowingPlaylistsView = false
    
    static let animation = Animation.easeOut(duration: 0.5)
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var namespace
    
    @State private var isShowingMiniPlayerViewBackground = false
    
    @State private var isFirstResponder = false
    
    @State private var cancellables: Set<AnyCancellable> = []

    var appDelegate: AppDelegate {
        NSApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: Geometry Effect Constants
    
    var playerViewIsSource: Bool {
        !playerManager.isShowingPlaylistsView
    }
    
    var playlistsViewIsSource: Bool {
        playerManager.isShowingPlaylistsView
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
        ZStack(alignment: .top) {
            if playerManager.isShowingPlaylistsView
                    || Self.debugIsShowingPlaylistsView {
                VStack(spacing: 0) {
                    
                    miniPlayerViewBackground
                    
                    PlaylistsScrollView()
                    
                }
                .background(
                    Rectangle()
                        .fill(BackgroundStyle())
                )
                // MARK: Playlists View Transition
                .transition(.move(edge: .bottom))
                .onExitCommand {
                    self.playerManager.dismissPlaylistsView(animated: true)
                }
                .onReceive(playerManager.popoverDidClose) {
                    self.playerManager.dismissPlaylistsView(animated: false)
                }
                
                miniPlayerView
                    .padding(.top, 33)
                    
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
        .onChange(of: playerManager.isShowingPlaylistsView) { isShowing in
            if isShowing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.linear(duration: 0.2)) {
                        self.isShowingMiniPlayerViewBackground = true
                    }
                }
            }
            else {
                self.isShowingMiniPlayerViewBackground = false
            }
        }
        .onExitCommand {
            if self.playerManager.isShowingPlaylistsView {
                self.playerManager.dismissPlaylistsView(animated: true)
            }
            else {
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
                        perform: playerManager.openCurrentPlaybackInSpotify
                    )
                    .help(playerManager.currentTrack?.name ?? "")

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
                        perform: playerManager.openArtistOrShowInSpotify
                    )
                    .help(playerManager.albumArtistTitle)
                
            }
            .padding(.horizontal, 10)
            .frame(height: 60)

            // MARK: Large Player Controls
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
                        .transition(.scale)
                        .padding(.top, 2)
                    PreviousTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: previousTrackButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .transition(.scale)
                    PlayPauseButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playPauseButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .transition(.scale)
                        .frame(width: 38, height: 38)
                    NextTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: nextTrackButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .transition(.scale)
                    RepeatModeButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: repeatModeButtonId,
                            in: namespace,
                            isSource: playerViewIsSource
                        )
                        .transition(.scale)
                        .padding(.top, 2)

                }
                .font(.largeTitle)

                SoundVolumeSlider()
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 5)

                Spacer()
                
                HStack {
                    // MARK: Show PlaylistsView Button
                    ShowPlaylistsButton()
                    
                    Spacer()

                    AvailableDevicesButton()
                        .padding(.bottom, 2)

                    // MARK: Show SettingsView Button
                    Button(action: {
                        AppDelegate.shared.openSettingsWindow()
                        
                    }, label: {
                        Image(systemName: "gearshape.fill")
                    })
                    .keyboardShortcut(",")
                    .buttonStyle(PlainButtonStyle())
                    .help("Show settings ⌘,")
                    
                }
                .padding(.top, 5)

            }
            .padding(.horizontal, 10)

            Spacer()
        }
        .background(
            KeyEventHandler { event in
                return self.playerManager.receiveKeyEvent(
                    event,
                    requireModifierKey: false
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
//        .border(Color.green, width: 5)
    }
    
    var miniPlayerView: some View {
        HStack(spacing: 0) {
            // MARK: Small Album Image
            playerManager.artworkImage
                .resizable()
                .cornerRadius(5)
                // MARK: Matched Geometry Effect
                .matchedGeometryEffect(
                    id: albumImageId,
                    in: namespace,
                    isSource: playlistsViewIsSource
                )
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .adaptiveShadow(radius: 2)
                .padding(.leading, 7)
                .padding(.trailing, 2)
                
            VStack(spacing: 0) {
                // MARK: Small Playing Title
                VStack(spacing: 3) {
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
                            perform: playerManager.openCurrentPlaybackInSpotify
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
                            perform: playerManager.openArtistOrShowInSpotify
                        )
                }
                Spacer()
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
                        .transition(.scale)
                    PreviousTrackButton(size: .small)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: previousTrackButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .transition(.scale)
                    PlayPauseButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playPauseButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .transition(.scale)
                        .frame(width: 20, height: 20)
                    NextTrackButton(size: .small)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: nextTrackButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .transition(.scale)
                    RepeatModeButton()
                        .scaleEffect(0.8)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: repeatModeButtonId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .transition(.scale)
                }
                .padding(.bottom, 3)
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 10)
            .frame(height: 70)
        }
    }

    var miniPlayerViewBackground: some View {
        VStack {
            Button(action: {
                self.playerManager.dismissPlaylistsView(animated: true)
            }, label: {
                Image(systemName: "chevron.down")
                    .padding(-3)
            })
            .padding(.top, 5)
            .keyboardShortcut("p")
                .padding(.top, 1)
            Spacer()
                .frame(height: 85)
        }
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(BackgroundStyle())
                .if(isShowingMiniPlayerViewBackground) {
                    $0.adaptiveShadow(radius: 3, y: 2)
                }
        )
        
    }
    
}

struct PlayerView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        Self.withAllColorSchemes {
            PlayerView()
                .environmentObject(playerManager.spotify)
                .environmentObject(playerManager)
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                )
                .onAppear(perform: onAppear)
        }
    }
    
    static func onAppear() {
        
    }
}
