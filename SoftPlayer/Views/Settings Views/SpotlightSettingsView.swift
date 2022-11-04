import SwiftUI
import Combine

struct SpotlightSettingsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
//    @EnvironmentObject var spotify: Spotify

    @State private var indexPlaylists = true
    @State private var indexPlaylistItems = true
    @State private var indexAlbums = true
    @State private var indexAlbumTracks = true

    @State private var isHovering = false

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
    
    var formattedProgress: String {
        if #available(macOS 12.0, *) {
            return self.playerManager.spotlightIndexingProgress
                .formatted(.percent.precision(.fractionLength(0)))
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            return formatter.string(from:
                NSNumber(value:
                    self.playerManager.spotlightIndexingProgress
                )
            ) ?? ""
            
        }
    }

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

            HStack {
                if hasChanges {
                    Text("Re-index Spotlight to save changes")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
            }
            .frame(height: 20)
//            .border(Color.green)

            Spacer()
            
            HStack {
                if playerManager.isIndexingSpotlight {
                    Button(action: cancelIndexingSpotlight, label: {
                        Text("Cancel Indexing Spotlight")
                    })
                }
                else {
                    Button(action: reIndexSpotlight, label: {
                        Text("Re-index Spotlight")
                    })
                    .disabled(indexSpotlightButtonIsDisabled)
                    .if(!playerManager.spotify.isAuthorized) { view in
                        view.help(mustLoginText)
                    }
                }
            }
//            .padding(.bottom, 5)
            .padding(.top, 20)
//            .border(Color.green)
            
            VStack(spacing: 0) {
                if playerManager.isIndexingSpotlight {
                    
                    ProgressView(
//                        "\(playerManager.spotlightIndexingProgress)",
                        value: playerManager.spotlightIndexingProgress
                    )
                    .modify { view in
                        if #available(macOS 13.0, *) {
                            view.tint(Color.green)
                        }
                        else {
                            view
                        }
                    }
                    HStack {
                        Text("Indexing Spotlight")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        if isHovering {
                            Text(formattedProgress)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    
                }
                else {
                    HStack {
                        Text("Indexes automatically every hour")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
//                    .border(Color.green)
                    Spacer()
                }
                
            }
            .frame(width: 250, height: 40)
//            .padding(.vertical, 10)
            .padding(.bottom, 20)
//            .border(Color.green)
            .onHover(
                enterDelay: 0.5,
                exitDelay: 0.1
            ) { isHovering in
                self.isHovering = isHovering
            }

        }
        .padding([.horizontal, .top], 20)
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
    
    func cancelIndexingSpotlight() {
        self.playerManager.isIndexingSpotlight = false
        self.playerManager.deleteAllCoreDataObjects()
        self.playerManager.deleteSpotlightIndex()
    }
    
}

struct SpotlightSettingsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        TabView {
            SpotlightSettingsView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .tabItem { Text("Spotlight") }
        }
        .padding()
        .frame(width: 400, height: 330)
    }
}

/*
 Text("Re-index Spotlight to save changes")
     .foregroundColor(.secondary)
     .font(.callout)
 */
