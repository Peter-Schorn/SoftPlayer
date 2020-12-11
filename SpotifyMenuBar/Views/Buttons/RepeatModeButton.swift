import SwiftUI
import Combine
import SpotifyWebAPI

struct RepeatModeButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var cycleRepeatModeCancellable: AnyCancellable? = nil
    
    var body: some View {
        Button(action: cycleRepeatMode, label: {
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
    }
    
    func cycleRepeatMode() {
        self.playerManager.repeatMode.cycle()
        self.cycleRepeatModeCancellable = self.spotify.api
            .setRepeatMode(to: self.playerManager.repeatMode)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    Loggers.repeatMode.error(
                        """
                        RepeatButton: couldn't set repeat mode to \
                        \(self.playerManager.repeatMode.rawValue)": \(error)
                        """
                    )
                }
                else {
                    Loggers.repeatMode.trace(
                        """
                        cycleRepeatMode completion: \
                        \(self.playerManager.repeatMode)
                        """
                    )
                }
            })
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
