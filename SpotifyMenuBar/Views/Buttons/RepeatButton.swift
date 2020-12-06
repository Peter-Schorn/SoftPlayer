import SwiftUI
import Combine
import SpotifyWebAPI

struct RepeatButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var cycleRepeatModeCancellable: AnyCancellable? = nil
    
    var body: some View {
        Button(action: cycleRepeatMode, label: repeatView)
            .buttonStyle(PlainButtonStyle())
            .disabled(repeatModeIsDisabled())
    }
    
    func repeatView() -> AnyView {
        switch playerManager.repeatMode {
            case .off:
                return Image(systemName: "repeat")
                    .font(.title2)
                    .eraseToAnyView()
            case .context:
                return Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(.green)
                    .eraseToAnyView()
            case .track:
                return Image(systemName: "repeat.1")
                    .font(.title2)
                    .foregroundColor(.green)
                    .eraseToAnyView()
        }
    }
    
    func cycleRepeatMode() {
        self.playerManager.repeatMode.cycle()
        let repeatMode = self.playerManager.repeatMode
        self.cycleRepeatModeCancellable = self.spotify.api
            .setRepeatMode(to: repeatMode)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print(
                        """
                        RepeatButton: couldn't set repeat mode to \
                        \(repeatMode.rawValue)": \(error)
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
        return !requiredActions.isSubset(of: playerManager.allowedActions)
    }
    
}


struct RepeatButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
