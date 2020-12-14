import SwiftUI
import Combine
import SpotifyWebAPI

struct RepeatModeButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var cycleRepeatModeCancellable: AnyCancellable? = nil
    
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
        .help("Change the repeat mode ⌘R")
    }
    
//    func cycleRepeatMode() {
//        self.playerManager.repeatMode.cycle()
//        self.cycleRepeatModeCancellable = self.spotify.api
//            .setRepeatMode(to: self.playerManager.repeatMode)
//            .receive(on: RunLoop.main)
//            .sink(receiveCompletion: { completion in
//                let repeatModeString = self.playerManager.repeatMode.rawValue
//                switch completion {
//                    case .failure(let error):
//                        let alertTitle =
//                            "Couldn't set repeat mode to \(repeatModeString)"
//                        self.playerManager.presentNotification(
//                            title: alertTitle,
//                            message: error.localizedDescription
//                        )
//                        Loggers.repeatMode.error(
//                            "RepeatButton: \(alertTitle): \(error)"
//                        )
//                    case .finished:
//                        Loggers.repeatMode.trace(
//                            "cycleRepeatMode completion: \(repeatModeString)"
//                        )
//                }
//
//            })
//    }
    
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
