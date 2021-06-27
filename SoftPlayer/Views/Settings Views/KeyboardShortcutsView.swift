import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutsView: View {
    
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
