import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct PlayerView: View {

    static var debugIsShowingLibraryView = false
    
    static let animation = Animation.easeOut(duration: 0.5)
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    @Environment(\.colorScheme) var colorScheme
    
    @Namespace var namespace
    
    
    @State private var cancellables: Set<AnyCancellable> = []

    // MARK: Geometry Effect Constants
    
    var playerViewIsSource: Bool {
//        !playerManager.isShowingLibraryView
        true
    }
    
    var playlistsViewIsSource: Bool {
//        playerManager.isShowingLibraryView
        true
    }
    
    let albumImageId = "albumImage"
    let trackEpisodeNameId = "trackEpisodeTitle"
    let albumArtisTitleId = "albumArtistTitle"

    let shuffleButtonId = "shuffleButton"
    let previousTrackButtonId = "previousTrack"
    let playPauseButtonId = "playPauseButton"
    let nextTrackButtonId = "nextTrack"
    let repeatModeButtonId = "repeatModeButton"

    // MARK: DEBUG
    
//    let trackTitle = "Tabu"
//    let albumArtistTitle = "Gustavo Cerati - Bocanada"

    // MARK: - Begin Views -
    
    var body: some View {
        ZStack(alignment: .top) {
            if playerManager.isShowingLibraryView
                || Self.debugIsShowingLibraryView {
                VStack(spacing: 0) {
                    
                    miniPlayerViewBackground
                    
                    LibraryView()
                    
                }
                .background(
                    Rectangle()
                        .fill(BackgroundStyle())
                )
                // MARK: Library View Transition
                .transition(.move(edge: .bottom))
                .onExitCommand {
                    self.playerManager.dismissLibraryView(animated: true)
                }
                .onReceive(playerManager.popoverDidClose) {
                    self.playerManager.dismissLibraryView(animated: false)
                }
                
                miniPlayerView
                
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
        .onExitCommand {
            if self.playerManager.isShowingLibraryView {
                self.playerManager.dismissLibraryView(animated: true)
            }
            else {
                AppDelegate.shared.closePopover()
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
//                Text(trackTitle)
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
                    .onDragOptional(
                        playingTitleItemProvider,
                        preview: playingTitleDragPreview
                    )
                    .help(playerManager.currentTrack?.name ?? "")

                Text(playerManager.albumArtistTitle)
//                Text(albumArtistTitle)
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
                    .onDragOptional(
                        albumArtistTitleItemProvider,
                        preview: albumArtistTitleDragPreview
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
                    // MARK: Show LibraryView Button
                    ShowLibraryButton()
                    
                    SaveTrackButton()

                    if let url = playerManager.currentItemIdentifier?.url {
                        SharingServicesMenu(item: url)
                            .frame(width: 33)
                    }


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
                    .help(Text("Show settings ⌘,"))
                    
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
                .frame(width: 70, height: 70)
                .adaptiveShadow(radius: 2)
                .padding(.leading, 7)
                .padding(.trailing, 2)
            
            VStack(spacing: 0) {
                // MARK: Small Playing Title
                VStack(spacing: 3) {
                    Text(playerManager.currentTrack?.name ?? "")
                    //                    Text(trackTitle)
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
                        .onDragOptional(
                            playingTitleItemProvider,
                            preview: playingTitleDragPreview
                        )
                        .onTapGesture(
                            perform: playerManager.openCurrentPlaybackInSpotify
                        )
                    Text(playerManager.albumArtistTitle)
                    //                    Text(albumArtistTitle)
                        .font(.footnote)
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: albumArtisTitleId,
                            in: namespace,
                            isSource: playlistsViewIsSource
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onDragOptional(
                            albumArtistTitleItemProvider,
                            preview: albumArtistTitleDragPreview
                        )
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
        .padding(.top, 40)
    }

    var miniPlayerViewBackground: some View {
        VStack {
            HStack {
                Button(action: {
                    self.playerManager.dismissLibraryView(animated: true)
                }, label: {
                    Image(systemName: "chevron.down")
                        .padding(-3)
                })
                .padding(3)
                
                Spacer()

                LibrarySegmentedControl()

            }
            .padding(.horizontal, 5)
            .padding(.top, 7)
            
            Spacer()
                .frame(height: 87)
        }
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(BackgroundStyle())
                .adaptiveShadow(radius: 3, y: 2)
        )
        
    }
    
    // MARK: Dragging

    func playingTitleItemProvider() -> NSItemProvider? {
        guard let url = self.playerManager.currentItemIdentifier?.url else {
            return nil
        }
        let provider = NSItemProvider(object: url as NSURL)
        provider.suggestedName = self.playerManager.currentTrack?.name
        return provider
    }
    
    func playingTitleDragPreview() -> some View {
        
        let title = self.playerManager.currentTrack?.name ?? ""
        let url = self.playerManager.currentItemIdentifier?.url
        
//        print(
//            """
//            playingTitleDragPreview: \
//            title: \(title); \
//            url: \(url as Any)
//            """
//        )

        return self.dragPreview(
            title: title,
            url: url
        )
    }
    
    func albumArtistTitleItemProvider() -> NSItemProvider? {
        
        guard let url = self.playerManager.showOrArtistURL else {
            return nil
        }
        let provider = NSItemProvider(object: url as NSURL)
        provider.suggestedName = self.playerManager.showOrArtistName
        return provider
    }
    
    func albumArtistTitleDragPreview() -> some View {

        let title = self.playerManager.showOrArtistName ?? ""
        let url = self.playerManager.showOrArtistURL
        
//        print(
//            """
//            albumArtistTitleDragPreview: \
//            title: \(title); \
//            url: \(url as Any)
//            """
//        )

        return self.dragPreview(
            title: title,
            url: url
        )
    }

    func dragPreview(
        title: String,
        url: URL?
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: nil) {
                Text(verbatim: title)
                    .fontWeight(.semibold)
                    .font(.caption)
                if let url = url {
                    Text(verbatim: url.absoluteString)
//                    Text(verbatim: "https://www.example.com")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .truncationMode(.middle)
                }
                    
            }
        }
        .padding(5)
        .lineLimit(1)
        .background(
            Rectangle()
                .fill(BackgroundStyle())
        )
        .cornerRadius(5)
        .opacity(0.8)
        .frame(minWidth: 200)
    }

}


@available(macOS 12.0, *)
struct PlayerView_Previews: PreviewProvider {
    
    static let spotify = Spotify()
    static let playerManager = PlayerManager(spotify: spotify)
    static let playerManager2 = PlayerManager(spotify: spotify)
    
    static var previews: some View {
        Self.withAllColorSchemes {
            PlayerView()
                .environmentObject(playerManager.spotify)
                .environmentObject(playerManager)
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                )
                .background(.regularMaterial)
                .background()
                .onAppear(perform: onAppear)
            
            PlayerView()
                .environmentObject(playerManager2.spotify)
                .environmentObject(playerManager2)
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                )
                .onAppear(perform: onAppear)

        }
    }
    
    static func onAppear() {
        playerManager2.isShowingLibraryView = true
    }
    
}
