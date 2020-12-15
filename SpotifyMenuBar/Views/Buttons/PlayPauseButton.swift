import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct PlayPauseButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var tooltip: String {
        var tooltip = "Play or pause playback"
        if let name = KeyboardShortcuts.getShortcut(for: .playPause) {
            tooltip += " \(name)"
        }
        return tooltip
    }

    var body: some View {
        Button(action: playerManager.playPause, label: {
            if self.playerManager.player.playerState == .playing {
                Image(systemName: "pause.circle.fill")
                    .resizable()
            }
            else {
                Image(systemName: "play.circle.fill")
                    .resizable()
            }
        })
        .buttonStyle(PlainButtonStyle())
        .help(tooltip)
    }
    
}

struct PlayPauseButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
