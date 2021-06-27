import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct PreviousTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @GestureState var isLongPressing = false
    
    @State private var seekBackwardsTimerCancellable: Cancellable? = nil
    
    let size: Size
    
    var shortcutName: String {
        if let name = KeyboardShortcuts.getShortcut(for: .previousTrack) {
            return " \(name)"
        }
        return ""
    }
    
    var skipToPreviousTrackIsEnabled: Bool {
        return playerManager.allowedActions.contains(.skipToPrevious)
    }

    var body: some View {
        
        // MARK: Seek Backwards 15 Seconds
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            Button(action: playerManager.seekBackwards15Seconds, label: {
                Image(systemName: "gobackward.15")
                    .font(size == .large ? .title : .body)
            })
            .buttonStyle(PlainButtonStyle())
            .help(Text("Seek backwards 15 seconds\(shortcutName)"))
        }
        else {
            Image(systemName: "backward.end.fill")
                .tapAndLongPressAndHoldGesture(
                    onTap: playerManager.skipToPreviousTrack,
                    isLongPressing: $isLongPressing
                )
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
                .help(Text("Skip to the previous track\(shortcutName)"))

        }
    }
    
}

struct PreviousTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
