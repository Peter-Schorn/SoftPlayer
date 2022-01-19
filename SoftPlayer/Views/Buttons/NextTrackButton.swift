import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct NextTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState private var gestureState = TapAndLongPressGestureState()

    @State private var seekForwardsTimerCancellable: Cancellable? = nil
    
    let size: Size
    
    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .nextTrack) {
            return " \(name)"
        }
        return ""
    }
    
    var skipToPreviousTrackIsEnabled: Bool {
        return playerManager.allowedActions.contains(.skipToNext)
    }
    
    var buttonOpacity: Double {
        if gestureState.isTapping || gestureState.isLongPressing {
            return 0.8
        }
        return 1
    }
    
    var body: some View {
        
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            // MARK: Seek Forwards 15 Seconds
            Button(action: playerManager.seekForwards15Seconds, label: {
                Image(systemName: "goforward.15")
                    .font(size == .large ? .title : .body)

            })
            .buttonStyle(PlainButtonStyle())
            .help(Text("Seek forwards 15 seconds\(shortcutName)"))
        }
        else {
            // MARK: Next Track
            
            Image(systemName: "forward.end.fill")
                .opacity(buttonOpacity)
                .scaleEffect(gestureState.isLongPressing ? 0.8 : 1)
                .animation(
                    .easeIn(duration: 0.1),
                    value: gestureState.isLongPressing
                )
                .tapAndLongPressAndHoldGesture(
                    $gestureState,
                    onTap: onTap
                )
                .help(Text("Skip to the next track\(shortcutName)"))
                .onChange(of: gestureState.isLongPressing) { isLongPressing in
                    if isLongPressing {
                        self.playerManager.seekForwards15Seconds()
                        self.seekForwardsTimerCancellable = Timer.publish(
                            every: 0.75, on: .main, in: .common
                        )
                        .autoconnect()
                        .sink { _ in
                            self.playerManager.seekForwards15Seconds()
                        }

                    }
                    else {
                        self.seekForwardsTimerCancellable?.cancel()

                    }
                }
                

        }
    }
    
    func onTap() {
        self.playerManager.skipToNextTrack()
    }
    
}

struct NextTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
