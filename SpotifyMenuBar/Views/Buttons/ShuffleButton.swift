import SwiftUI
import Combine
import SpotifyWebAPI

struct ShuffleButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Button(action: {
            self.playerManager.shuffleIsOn.toggle()
            self.playerManager.player.setShuffling?(
                playerManager.shuffleIsOn
            )
        }, label: {
            Image(systemName: "shuffle")
                .font(.title2)
                .foregroundColor(
                    playerManager.shuffleIsOn ? .green : .primary
                )
        })
        .buttonStyle(PlainButtonStyle())
        .disabled(!playerManager.allowedActions.contains(.toggleShuffle))
    }
    
}

struct ShuffleButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
