import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct PreviousTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @GestureState private var gestureState = TapAndLongPressGestureState()
    
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

    var buttonOpacity: Double {
        if gestureState.isTapping || gestureState.isLongPressing {
            return 0.8
        }
        return 1
    }
    
    var body: some View {
        
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            // MARK: Seek Backwards 15 Seconds
            Button(action: playerManager.seekBackwards15Seconds, label: {
                Image(systemName: "gobackward.15")
                    .font(size == .large ? .title : .body)
            })
            .buttonStyle(PlainButtonStyle())
            .help(Text("Seek backwards 15 seconds\(shortcutName)"))
        }
        else {
            Image(systemName: "backward.end.fill")
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
                .help(Text("Skip to the previous track\(shortcutName)"))
                .onChange(of: gestureState.isLongPressing) { isLongPressing in
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
                

        }
    }
    
    func onTap() {
        self.playerManager.skipToPreviousTrack()
    }
    
}

struct PreviousTrackButton_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        Group {
            PreviousTrackButton(size: .large)
            PreviousTrackButton(size: .small)
        }
        .padding()
        .environmentObject(playerManager)
        .environmentObject(playerManager.spotify)
    }
}
