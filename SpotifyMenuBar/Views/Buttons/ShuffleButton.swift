import SwiftUI
import Combine
import SpotifyWebAPI
import Logging
import KeyboardShortcuts

struct ShuffleButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    var tooltip: String {
        var tooltip = "Toggle shuffle"
        if let name = KeyboardShortcuts.getShortcut(for: .shuffle) {
            tooltip += " \(name)"
        }
        return tooltip
    }

    var body: some View {
        Button(action: playerManager.toggleShuffle, label: {
            Image(systemName: "shuffle")
                .font(.title2)
                .foregroundColor(
                    playerManager.shuffleIsOn ? .green : .primary
                )
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(!playerManager.allowedActions.contains(.toggleShuffle))
        .help(tooltip)
    }
    
}

struct ShuffleButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
