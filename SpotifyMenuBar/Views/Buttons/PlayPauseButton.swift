import SwiftUI
import Combine
import SpotifyWebAPI

struct PlayPauseButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Button(action: {
            self.playerManager.player.playpause?()
        }, label: {
            if self.playerManager.player.playerState == .playing {
                Image(systemName: "pause.circle.fill")
                    .resizable()
            }
            else {
                Image(systemName: "play.circle.fill")
                    .resizable()
            }
        })
        .buttonStyle(PlainButtonStyle())
//        .disabled(playPauseIsDisabled)
        
    }
    
    var playPauseIsDisabled: Bool {
        switch self.playerManager.player.playerState {
            case .playing:
                return !self.playerManager.allowedActions.contains(.pause)
            case .stopped, .paused:
                return !self.playerManager.allowedActions.contains(.resume)
            default:
                return false
        }
    }

}

struct PlayPauseButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
