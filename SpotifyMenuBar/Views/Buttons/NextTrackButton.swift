import SwiftUI
import Combine
import SpotifyWebAPI

struct NextTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState var isLongPressing = false

    @State private var seekForwardsTimerCancellable: Cancellable? = nil
    
    var body: some View {
        
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            // MARK: Seek Forwards 15 Seconds
            Button(action: seekForwards15Seconds, label: {
                Image(systemName: "goforward.15")
                    .font(.title)
            })
            .buttonStyle(PlainButtonStyle())
        }
        else {
            // MARK: Next Track
            
            Image(systemName: "forward.end.fill")
                .tapAndLongPressAndHoldGesture(
                    onTap: { self.playerManager.player.nextTrack?() },
                    isLongPressing: $isLongPressing
                )
                .disabled(!playerManager.allowedActions.contains(.skipToNext))
                .onChange(of: isLongPressing) { isLongPressing in
                    if isLongPressing {
                        self.seekForwards15Seconds()
                        self.seekForwardsTimerCancellable = Timer.publish(
                            every: 0.75, on: .main, in: .common
                        )
                        .autoconnect()
                        .sink { _ in
                            self.seekForwards15Seconds()
                        }
                        
                    }
                    else {
                        self.seekForwardsTimerCancellable?.cancel()
                        
                    }
                }
        }
    }
    
    func seekForwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            print("NextTrackButton: couldn't get player position")
            return
        }
        let newPosition: Double
        if let duration = self.playerManager.currentTrack?.duration {
            newPosition = (currentPosition + 15)
                .clamped(to: 0...Double(duration / 1000))
        }
        else {
            newPosition = currentPosition + 15
        }
        self.playerManager.setPlayerPosition(to: CGFloat(newPosition))
    }
    
}

struct NextTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
