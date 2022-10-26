import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct PlayPauseButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .playPause) {
            return " \(name)"
        }
        return ""
    }

    var body: some View {
        Button(action: playerManager.playPause, label: {
            if self.playerManager.spotifyApplication?.playerState == .playing {
                Image(systemName: "pause.circle.fill")
                    .resizable()
            }
            else {
                Image(systemName: "play.circle.fill")
                    .resizable()
            }
        })
        .buttonStyle(PlainButtonStyle())
        .help(Text("Play or pause playback\(shortcutName)"))
    }
    
}

struct PlayPauseButton_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(
        spotify: Spotify(),
        viewContext: AppDelegate.shared.persistentContainer.viewContext
    )

    static var previews: some View {
        PlayPauseButton()
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
