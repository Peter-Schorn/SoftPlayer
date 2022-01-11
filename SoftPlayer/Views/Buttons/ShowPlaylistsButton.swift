import SwiftUI
import KeyboardShortcuts

struct ShowPlaylistsButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .showPlaylists) {
            return " \(name)"
        }
        return ""
    }

    var keyboardShortcut: KeyboardShortcut? {
        guard let shortcut = KeyboardShortcuts
                .getShortcut(for: .showPlaylists) else {
            return nil
        }
        return KeyboardShortcut.init(shortcut)
    }

    var body: some View {
        Button(action: {
            if self.playerManager.isShowingLibraryView {
                self.playerManager.dismissPlaylistsView(animated: true)
            }
            else {
                self.playerManager.presentPlaylistsView()
            }
        }, label: {
            Image(systemName: "music.note.list")
        })
        .ifLet(keyboardShortcut) { view, shortcut in
            view.keyboardShortcut(shortcut)
        }
        .help(Text("Show playlists\(shortcutName)"))
    }
}

struct ShowPlaylistsButton_Previews: PreviewProvider {
    static var previews: some View {
        ShowPlaylistsButton()
    }
}
