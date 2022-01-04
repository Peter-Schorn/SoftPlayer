import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct SaveTrackButton: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var helpText: Text {
        if self.playerManager.currentTrackIsSaved {
            return Text("Remove from Liked Songs")
        }
        else {
            return Text("Add to Liked Songs")
        }
    }

    var body: some View {
        if playerManager.currentTrack?.identifier?.idCategory == .track {
            Button(
                action: playerManager.addOrRemoveCurrentItemFromSavedTracks
            ) {
                let imageName = self.playerManager.currentTrackIsSaved ? "heart.fill" : "heart"
                Image(systemName: imageName)
                    .font(.title2)
                    .foregroundColor(
                        self.playerManager.currentTrackIsSaved ?
                            .green : nil
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .help(helpText)
        }
    }
    
}

struct SaveTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
