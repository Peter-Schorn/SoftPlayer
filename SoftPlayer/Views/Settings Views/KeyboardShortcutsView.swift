import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        VStack {
            shortcutView(
                for: .showPlaylists,
                label: Text("Show playlists")
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
                for: .volumeDown,
                label: Text("Volume down")
            )
            shortcutView(
                for: .volumeUp,
                label: Text("Volume Up")
            )
            shortcutView(
                for: .onlyShowMyPlaylists,
                label: Text("Toggle only show my playlists")
            )
            
            Button(action: KeyboardShortcuts.resetAll, label: {
                Text("Restore Defaults")
            })
            .padding(.top, 10)

        }
        .background(
            KeyEventHandler { event in
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            KeyboardShortcuts.Recorder(for: name)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}


struct KeyboardShortcutsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        TabView {
            KeyboardShortcutsView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .tabItem { Text("Shortcuts") }
            
        }
        .padding()
        .frame(width: 450, height: 470)
    }

}
