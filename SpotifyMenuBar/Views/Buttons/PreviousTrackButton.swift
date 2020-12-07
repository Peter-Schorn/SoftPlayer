import SwiftUI
import Combine
import SpotifyWebAPI

struct PreviousTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState var isLongPressing = false

    @State private var seekBackwardsTimerCancellable: Cancellable? = nil
    
    var body: some View {
        
            // MARK: Seek Backwards 15 Seconds
            if playerManager.currentTrack?.identifier?.idCategory == .episode {
                Button(action: seekBackwards15Seconds, label: {
                    Image(systemName: "gobackward.15")
                        .font(.title)
                })
                .buttonStyle(PlainButtonStyle())
            }
            else {
                Image(systemName: "backward.end.fill")
                    .tapAndLongPressAndHoldGesture(
                        onTap: {
                            self.playerManager.player.previousTrack?()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                self.playerManager.updatePlayerState()
                            }
                        },
                        isLongPressing: $isLongPressing
                    )
                    .disabled(!playerManager.allowedActions.contains(.skipToPrevious))
                    .onChange(of: isLongPressing) { isLongPressing in
                        if isLongPressing {
                            self.seekBackwards15Seconds()
                            self.seekBackwardsTimerCancellable = Timer.publish(
                                every: 0.75, on: .main, in: .common
                            )
                            .autoconnect()
                            .sink { _ in
                                self.seekBackwards15Seconds()
                            }
                            
                        }
                        else {
                            self.seekBackwardsTimerCancellable?.cancel()
                        }
                    }

            }
        
            
    }
    
    func seekBackwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            print("PreviousTrackButton: couldn't get player position")
            return
        }
        let newPosition = max(0, currentPosition - 15)
        self.playerManager.setPlayerPosition(to: CGFloat(newPosition))
    }
    
}

struct PreviousTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}

