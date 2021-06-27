import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct RepeatModeButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var cycleRepeatModeCancellable: AnyCancellable? = nil
    
    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .repeatMode) {
            return " \(name)"
        }
        return ""
    }

    var body: some View {
        Button(action: playerManager.cycleRepeatMode, label: {
            if playerManager.repeatMode == .context {
                Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            else if playerManager.repeatMode == .track {
                Image(systemName: "repeat.1")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            else {
                Image(systemName: "repeat")
                    .font(.title2)
            }
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(repeatModeIsDisabled())
        .help(Text("Change the repeat mode\(shortcutName)"))
    }
    
    func repeatModeIsDisabled() -> Bool {
        let requiredActions: Set<PlaybackActions> = [
            .toggleRepeatContext,
            .toggleRepeatTrack
        ]
        return !requiredActions.isSubset(
            of: playerManager.allowedActions
        )
    }
    
}


struct RepeatModeButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
