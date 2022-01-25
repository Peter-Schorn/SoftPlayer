import SwiftUI
import KeyboardShortcuts

struct ShowLibraryButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .showLibrary) {
            return " \(name)"
        }
        return ""
    }

    var keyboardShortcut: KeyboardShortcut? {
        guard let shortcut = KeyboardShortcuts
                .getShortcut(for: .showLibrary) else {
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
            Image(systemName: "music.note.house.fill")
        })
        .ifLet(keyboardShortcut) { view, shortcut in
            view.keyboardShortcut(shortcut)
        }
        .help(Text("Show library\(shortcutName)"))
    }
}

struct ShowLibraryButton_Previews: PreviewProvider {
    static var previews: some View {
        ShowLibraryButton()
    }
}
