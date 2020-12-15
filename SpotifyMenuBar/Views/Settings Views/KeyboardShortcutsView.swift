import SwiftUI
import KeyboardShortcuts

struct KeyboardShortcutsView: View {
    
    var body: some View {
        VStack {
            shortcutView(
                for: .showPlaylists,
                label: "Show playlists"
            )
            shortcutView(
                for: .previousTrack,
                label: "Previous track"
            )
            shortcutView(
                for: .playPause,
                label: "Play and pause"
            )
            shortcutView(
                for: .nextTrack,
                label: "Next track"
            )
            shortcutView(
                for: .repeatMode,
                label: "Repeat mode"
            )
            shortcutView(
                for: .shuffle,
                label: "Shuffle"
            )
            shortcutView(
                for: .volumeDown,
                label: "Volume down"
            )
            shortcutView(
                for: .volumeUp,
                label: "Volume Up"
            )
            shortcutView(
                for: .onlyShowMyPlaylists,
                label: "Toggle only show my playlists"
            )
            Button("Restore Defaults", action: KeyboardShortcuts.resetAll)
        }
    }
    
    func shortcutView(
        for name: KeyboardShortcuts.Name,
        label: String
    ) -> some View {
        HStack {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .trailing)
            KeyboardShortcuts.Recorder(for: name)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}
