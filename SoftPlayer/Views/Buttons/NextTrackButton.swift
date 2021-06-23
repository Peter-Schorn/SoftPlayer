import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct NextTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState var isLongPressing = false

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
    
    var body: some View {
        
        if playerManager.currentlyPlayingContext?.context?.type == .show {
            // MARK: Seek Forwards 15 Seconds
            Button(action: playerManager.seekForwards15Seconds, label: {
                Image(systemName: "goforward.15")
                    .font(size == .large ? .title : .body)

            })
            .buttonStyle(PlainButtonStyle())
            .help("Seek forwards 15 seconds\(shortcutName)")
        }
        else {
            // MARK: Next Track
            
            Image(systemName: "forward.end.fill")
                .tapAndLongPressAndHoldGesture(
                    onTap: self.playerManager.skipToNextTrack,
                    isLongPressing: $isLongPressing
                )
                .onChange(of: isLongPressing) { isLongPressing in
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
                .help("Skip to the next track\(shortcutName)")

        }
    }
    
}

struct NextTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
