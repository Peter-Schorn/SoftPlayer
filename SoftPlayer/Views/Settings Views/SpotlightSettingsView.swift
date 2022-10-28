import SwiftUI
import Combine

struct SpotlightSettingsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    var indexSpotlightButtonIsDisabled: Bool {
        !self.playerManager.spotify.isAuthorized ||
            self.playerManager.isIndexingSpotlight
    }

    let mustLoginText = Text(
        """
        You must log in with Spotify to enable spotlight indexing
        """
    )

    var body: some View {
        Form {
            Group {
                Toggle(
                    "Index Playlists",
                    isOn: playerManager.$indexPlaylists
                )
                Toggle(
                    "Index Playlist Tracks and Episodes",
                    isOn: playerManager.$indexPlaylists
                )
                Toggle(
                    "Index Albums",
                    isOn: playerManager.$indexAlbums
                )
                Toggle(
                    "Index Album Tracks",
                    isOn: playerManager.$indexAlbumTracks
                )
            }
            .disabled(playerManager.isIndexingSpotlight)

            Spacer()
            
            HStack {
                Button {
                    self.playerManager.deleteAllCoreDataObjects()
                    self.playerManager.deleteSpotlightIndex()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.playerManager.indexSpotlight()
//                    }
                } label: {
                    Text("Re-index Spotlight")
                }
                .disabled(indexSpotlightButtonIsDisabled)
                .if(!playerManager.spotify.isAuthorized) { view in
                    view.help(mustLoginText)
                }
            }
            .padding(.vertical, 5)
            .padding(.trailing, 35)
            .versionedOverlay(alignment: .trailing) {
                if playerManager.isIndexingSpotlight {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
//            .border(Color.green)
            
        }
        .padding()
        .background(
            KeyEventHandler(name: "SpotlightSettingsView") { event in
                return self.playerManager.receiveKeyEvent(
                    event,
                    requireModifierKey: true
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        
    }
    
}

struct SpotlightSettingsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )

    static var previews: some View {
        TabView {
            SpotlightSettingsView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .tabItem { Text("Spotlight") }
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
