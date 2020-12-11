import SwiftUI
import Combine
import SpotifyWebAPI
import Logging

struct ShuffleButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    var body: some View {
        Button(action: {
            self.playerManager.shuffleIsOn.toggle()
            Loggers.shuffle.trace(
                "will set shuffle to \(self.playerManager.shuffleIsOn)"
            )
            self.playerManager.player.setShuffling?(
                self.playerManager.shuffleIsOn
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
