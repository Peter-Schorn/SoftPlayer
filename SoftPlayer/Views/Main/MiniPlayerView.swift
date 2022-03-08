import SwiftUI

struct MiniPlayerView: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    let namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            // MARK: Small Album Image
            playerManager.artworkImage
                .resizable()
                .cornerRadius(5)
            // MARK: Matched Geometry Effect
                .matchedGeometryEffect(
                    id: playerManager.albumImageId,
                    in: namespace,
                    isSource: playerManager.playlistsViewIsSource
                )
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
                            id: playerManager.trackEpisodeNameId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onDragOptional(
                            playerManager.playingTitleItemProvider,
                            preview: playerManager.playingTitleDragPreview
                        )
                        .onTapGesture(
                            perform: playerManager.openCurrentPlaybackInSpotify
                        )
                    Text(playerManager.albumArtistTitle)
                        .font(.footnote)
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.albumArtisTitleId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onDragOptional(
                            playerManager.albumArtistTitleItemProvider,
                            preview: playerManager.albumArtistTitleDragPreview
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
                            id: playerManager.shuffleButtonId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .transition(.scale)
                    PreviousTrackButton(size: .small)
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.previousTrackButtonId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .transition(.scale)
                    PlayPauseButton()
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.playPauseButtonId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .transition(.scale)
                        .frame(width: 20, height: 20)
                    NextTrackButton(size: .small)
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.nextTrackButtonId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
                        )
                        .transition(.scale)
                    RepeatModeButton()
                        .scaleEffect(0.8)
                    // MARK: Matched Geometry Effect
                        .matchedGeometryEffect(
                            id: playerManager.repeatModeButtonId,
                            in: namespace,
                            isSource: playerManager.playlistsViewIsSource
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
}

struct MiniPlayerView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    @Namespace static var namespace

    static var previews: some View {
        MiniPlayerView(namespace: namespace)
            .frame(width: AppDelegate.popoverWidth)
            .environmentObject(playerManager)
    }
}
