import SwiftUI
import Combine
import SpotifyWebAPI

struct PreviousTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
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
                // MARK: Previous Track
                Button(action: {
                    self.playerManager.player.previousTrack?()
                }, label: {
                    Image(systemName: "backward.end.fill")
                })
                .buttonStyle(PlainButtonStyle())
                .disabled(!playerManager.allowedActions.contains(.skipToPrevious))
                .onLongPressGesture(perform: seekBackwards15Seconds)
            }
    }
    
    func seekBackwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            print("PreviousTrackButton: couldn't get player position")
            return
        }
        self.playerManager.setPlayerPosition(
            to: CGFloat(currentPosition - 15)
        )
    }
    
}

struct PreviousTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}

