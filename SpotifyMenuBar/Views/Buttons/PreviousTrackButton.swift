import SwiftUI
import Combine
import SpotifyWebAPI

struct PreviousTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState var isLongPressing = false
    
    @State private var seekBackwardsTimerCancellable: Cancellable? = nil
    
    let size: Size
    
    var body: some View {
        
        // MARK: Seek Backwards 15 Seconds
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            Button(action: playerManager.seekBackwards15Seconds, label: {
                Image(systemName: "gobackward.15")
                    .font(size == .large ? .title : .body)
            })
            .buttonStyle(PlainButtonStyle())
            .help("Seek backwords 15 seconds ⌘←")
        }
        else {
            Image(systemName: "backward.end.fill")
                .tapAndLongPressAndHoldGesture(
                    onTap: playerManager.skipToPreviousTrack,
                    isLongPressing: $isLongPressing
                )
                .disabled(!playerManager.allowedActions.contains(.skipToPrevious))
                .onChange(of: isLongPressing) { isLongPressing in
                    if isLongPressing {
                        self.playerManager.seekBackwards15Seconds()
                        self.seekBackwardsTimerCancellable = Timer.publish(
                            every: 0.75, on: .main, in: .common
                        )
                        .autoconnect()
                        .sink { _ in
                            self.playerManager.seekBackwards15Seconds()
                        }
                        
                    }
                    else {
                        self.seekBackwardsTimerCancellable?.cancel()
                    }
                }
                .help("Skip to the previous track ⌘←")

        }
    }
    
}

struct PreviousTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
