import SwiftUI
import Combine

struct SpotlightSettingsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    @State private var indexPlaylists = true
    @State private var indexPlaylistItems = true
    @State private var indexAlbums = true
    @State private var indexAlbumTracks = true

    /// Whether or not the user has changed the settings for which items to
    /// index since the last time spotlight has been re-indexed.
    var hasChanges: Bool {
        self.playerManager.indexPlaylists
                != self.indexPlaylists ||
                self.playerManager.indexPlaylistItems !=
                self.indexPlaylistItems ||
                self.playerManager.indexAlbums !=
                self.indexAlbums ||
                self.playerManager.indexAlbumTracks !=
                self.indexAlbumTracks
    }

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
                    isOn: $indexPlaylists
                )
                Toggle(
                    "Index Playlist Tracks and Episodes",
                    isOn: $indexPlaylistItems
                )
                Toggle(
                    "Index Albums",
                    isOn: $indexAlbums
                )
                Toggle(
                    "Index Album Tracks",
                    isOn: $indexAlbumTracks
                )
            }
            .disabled(playerManager.isIndexingSpotlight)

            Spacer()
            
            HStack {
                Button(action: reIndexSpotlight, label: {
                    Text("Re-index Spotlight")
                })
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
            
            HStack {
                if hasChanges {
                    Text("Re-index Spotlight to save changes")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
            }
            .frame(height: 20)
//            .border(Color.blue)
            
        }
        .padding()
        .onAppear(perform: onAppear)
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
    
    func onAppear() {
        self.indexPlaylists = self.playerManager.indexPlaylists
        self.indexPlaylistItems = self.playerManager.indexPlaylistItems
        self.indexAlbums = self.playerManager.indexAlbums
        self.indexAlbumTracks = self.playerManager.indexAlbumTracks
    }
    
    func reIndexSpotlight() {
        
        self.playerManager.indexPlaylists = self.indexPlaylists
        self.playerManager.indexPlaylistItems = self.indexPlaylistItems
        self.playerManager.indexAlbums = self.indexAlbums
        self.playerManager.indexAlbumTracks = self.indexAlbumTracks

        self.playerManager.deleteAllCoreDataObjects()
        self.playerManager.deleteSpotlightIndex()
        self.playerManager.indexSpotlight()
        
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

/*
 Text("Re-index Spotlight to save changes")
     .foregroundColor(.secondary)
     .font(.callout)
 */
