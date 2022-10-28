import SwiftUI
import KeyboardShortcuts
import SpotifyWebAPI

struct KeyboardShortcutsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var body: some View {
        VStack {
            Group {
                shortcutView(
                    for: .openApp,
                    label: Text("Open App (global)")
                )
                shortcutView(
                    for: .showLibrary,
                    label: Text("Show Library")
                )
                shortcutView(
                    for: .previousTrack,
                    label: Text("Previous track")
                )
                shortcutView(
                    for: .playPause,
                    label: Text("Play and pause")
                )
                shortcutView(
                    for: .nextTrack,
                    label: Text("Next track")
                )
                shortcutView(
                    for: .repeatMode,
                    label: Text("Repeat mode")
                )
                shortcutView(
                    for: .shuffle,
                    label: Text("Shuffle")
                )
                shortcutView(
                    for: .likeTrack,
                    label: Text("Like Track")
                )
                shortcutView(
                    for: .volumeDown,
                    label: Text("Volume down")
                )
                shortcutView(
                    for: .volumeUp,
                    label: Text("Volume Up")
                )
            }
            Group {
                shortcutView(
                    for: .onlyShowMyPlaylists,
                       label: Text("Toggle only show my playlists")
                )
                shortcutView(
                    for: .settings,
                    label: Text("Settings")
                )
                shortcutView(
                    for: .quit,
                    label: Text("Quit")
                )
                
                Button(action: KeyboardShortcuts.resetAll, label: {
                    Text("Restore Defaults")
                })
                .padding(.top, 10)
                
            }


        }
        .background(
            KeyEventHandler(name: "KeyboardShortcutsView") { event in
                return self.playerManager.receiveKeyEvent(
                    event,
                    requireModifierKey: true
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        
    }
    
    func shortcutView(
        for name: KeyboardShortcuts.Name,
        label: Text
    ) -> some View {
        HStack {
            label
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            KeyboardShortcuts.Recorder(for: name)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}


struct KeyboardShortcutsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )
    
    static var previews: some View {
        TabView {
            KeyboardShortcutsView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .tabItem { Text("Shortcuts") }
            
        }
        .padding()
        .frame(width: 450, height: 550)
    }

}
