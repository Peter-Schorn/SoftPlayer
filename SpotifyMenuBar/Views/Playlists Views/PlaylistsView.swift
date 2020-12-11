import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import Logging

struct PlaylistsView: View {

    static let animation = Animation.easeInOut
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @Binding var isPresented: Bool
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    @State private var cancellables: Set<AnyCancellable> = []
    
    var playingEpisode: Bool {
        playerManager.currentTrack?.identifier?.idCategory == .episode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Button(action: {
                    self.dissmissView(animated: true)
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
            PlaylistsScrollView(isPresented: $isPresented)
        }
        .background(
            Rectangle().fill(BackgroundStyle())
        )
        .touchBar(content: PlayPlaylistsTouchBarView.init)
        .transition(.move(edge: .bottom))
        .onExitCommand {
           self.dissmissView(animated: true)
        }
        .onReceive(playerManager.popoverDidClose) {
            self.dissmissView(animated: false)
        }
    }
    
    var miniPlayerView: some View {
        HStack(spacing: 0) {
            playerManager.artworkImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .cornerRadius(5)
                .shadow(radius: 2)
            VStack(spacing: 0) {
                Group {
                    Text(playerManager.currentTrack?.name ?? "")
                        .fontWeight(.semibold)
                        .font(.callout)
                        .onTapGesture(
                            perform: playerManager.openCurrentPlaybackInBrowser
                        )
                    Text(playerManager.albumArtistTitle)
                        .font(.footnote)
                        .onTapGesture(
                            perform: playerManager.openArtistOrShowInBrowser
                        )
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(.vertical, 5)
            }
            .padding(5)
            .frame(height: 70)
        }
    }

    func dissmissView(animated: Bool) {
        if animated {
            withAnimation(Self.animation) {
                self.isPresented = false
            }
        }
        else {
            self.isPresented = false
        }
        self.playerManager.updatePlaylistsSortedByLastModifiedDate()
    }
    
}

struct PlaylistsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            PlaylistsView(isPresented: .constant(true))
                .environmentObject(playerManager.spotify)
                .environmentObject(playerManager)
                .frame(
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                )
                .preferredColorScheme(colorScheme)
        }
    }
}

/*
 .fill(colorScheme == .dark ? Color(#colorLiteral(red: 0.2453253074, green: 0.2453253074, blue: 0.2453253074, alpha: 1)) : Color(#colorLiteral(red: 0.9132540343, green: 0.9132540343, blue: 0.9132540343, alpha: 1)))
 */
