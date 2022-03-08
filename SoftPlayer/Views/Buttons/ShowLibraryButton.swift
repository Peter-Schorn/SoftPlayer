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

    var body: some View {
        Button(action: {
            if self.playerManager.isShowingLibraryView {
                self.playerManager.dismissLibraryView(animated: true)
            }
            else {
                self.playerManager.presentLibraryView()
            }
        }, label: {
            Image(systemName: "music.note.house.fill")
        })
        .help(Text("Show library\(shortcutName)"))
    }
}

struct ShowLibraryButton_Previews: PreviewProvider {
    static var previews: some View {
        ShowLibraryButton()
    }
}
