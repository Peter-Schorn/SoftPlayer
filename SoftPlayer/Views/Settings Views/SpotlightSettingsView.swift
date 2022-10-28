import SwiftUI
import Combine

struct SpotlightSettingsView: View {
    
    @EnvironmentObject var playerManager: PlayerManager

    var body: some View {
        if playerManager.spotify.isAuthorized {
            Button {
                // MARK: TODO: Re-retrieve playlists and albums first
                self.playerManager.indexSpotlight()
            } label: {
                Text("Re-index Spotlight")
            }
        }
    }
}

struct SpotlightSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SpotlightSettingsView()
    }
}
