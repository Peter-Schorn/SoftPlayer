import SwiftUI
import KeyboardShortcuts

struct ShowPlaylistsButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var tooltip: String {
        var tooltip = "Show playlists"
        if let name = KeyboardShortcuts.getShortcut(for: .showPlaylists) {
            tooltip += " \(name)"
        }
        return tooltip
    }

    var keyboardShortcut: KeyboardShortcut? {
        guard let shortcut = KeyboardShortcuts
                .getShortcut(for: .showPlaylists) else {
            return nil
        }
        return KeyboardShortcut(shortcut)
    }

    var body: some View {
        Button(action: {
            if self.playerManager.isShowingPlaylistsView {
                self.playerManager.dismissPlaylistsView(animated: true)
            }
            else {
                withAnimation(PlayerView.animation) {
                    self.playerManager.isShowingPlaylistsView = true
                }
            }
        }, label: {
            Image(systemName: "music.note.list")
        })
        .map(keyboardShortcut) { view, shortcut in
            view.keyboardShortcut(shortcut)
        }
        .help(tooltip)
    }
}

struct ShowPlaylistsButton_Previews: PreviewProvider {
    static var previews: some View {
        ShowPlaylistsButton()
    }
}
