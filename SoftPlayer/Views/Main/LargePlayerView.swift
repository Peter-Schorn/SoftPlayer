import SwiftUI

struct LargePlayerView: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    let namespace: Namespace.ID

    var body: some View {
        VStack(spacing: 5) {
            // MARK: Large Album Image
            playerManager.artworkImage
                .resizable()
                // MARK: Matched Geometry Effect
                .matchedGeometryEffect(
                    id: playerManager.albumImageId,
                    in: namespace,
                    anchor: .center,
                    isSource: playerManager.playerViewIsSource
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
                        id: playerManager.trackEpisodeNameId,
                        in: namespace,
                        isSource: playerManager.playerViewIsSource
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .onTapGesture(
                        perform: playerManager.openCurrentPlaybackInSpotify
                    )
                    .onDragOptional(
                        playerManager.playingTitleItemProvider,
                        preview: playerManager.playingTitleDragPreview
                    )
                    .help(playerManager.currentTrack?.name ?? "")

                Text(playerManager.albumArtistTitle)
//                Text(albumArtistTitle)
                    // MARK: Matched Geometry Effect
                    .matchedGeometryEffect(
                        id: playerManager.albumArtisTitleId,
                        in: namespace,
                        isSource: playerManager.playerViewIsSource
                    )
                    .lineLimit(1)
                    .foregroundColor(Color.primary.opacity(0.9))
                    .onTapGesture(
                        perform: playerManager.openArtistOrShowInSpotify
                    )
                    .onDragOptional(
                        playerManager.albumArtistTitleItemProvider,
                        preview: playerManager.albumArtistTitleDragPreview
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
                            id: playerManager.shuffleButtonId,
                            in: namespace,
                            isSource: playerManager.playerViewIsSource
                        )
                        .transition(.scale)
                        .padding(.top, 2)
                    PreviousTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.previousTrackButtonId,
                            in: namespace,
                            isSource: playerManager.playerViewIsSource
                        )
                        .transition(.scale)
                    PlayPauseButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.playPauseButtonId,
                            in: namespace,
                            isSource: playerManager.playerViewIsSource
                        )
                        .transition(.scale)
                        .frame(width: 38, height: 38)
                    NextTrackButton(size: .large)
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.nextTrackButtonId,
                            in: namespace,
                            isSource: playerManager.playerViewIsSource
                        )
                        .transition(.scale)
                    RepeatModeButton()
                        // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.repeatModeButtonId,
                            in: namespace,
                            isSource: playerManager.playerViewIsSource
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
}

struct LargePlayerView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    @Namespace static var namespace

    static var previews: some View {
        LargePlayerView(namespace: namespace)
            .frame(width: AppDelegate.popoverWidth)
            .environmentObject(playerManager)
    }
}
