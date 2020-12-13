import SwiftUI
import Combine
import SpotifyWebAPI

struct SettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Form {
            Button(
                "Remove Playlist Images Cache",
                action: removePlaylistImagesCache
            )
            Button(
                "Logout from Spotify",
                action: spotify.api.authorizationManager.deauthorize
            )
        }
        .padding(50)
    }
    
    func removePlaylistImagesCache() {
        do {
            if let folder = playerManager.imagesFolder {
                print("will delete folder: \(folder)")
                try FileManager.default.removeItem(at: folder)
            }
            
        } catch {
            print("couldn't remove image cache: \(error)")
        }
    }
    
    

}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
