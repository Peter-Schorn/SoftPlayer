import SwiftUI
import Combine
import SpotifyWebAPI

struct GeneralSettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Form {
            
            Button(action: showImagesCacheFolder, label: {
                Text("Show Images Folder")
            })
            Text(
                "You can safely remove files from this folder to free up space"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
            
            Button(action: spotify.api.authorizationManager.deauthorize, label: {
                Text("Logout from Spotify")
            })
            .disabled(!spotify.isAuthorized)
            
            Text(
                "All user data will be removed"
            )
            .font(.footnote)
            .foregroundColor(.secondary)

            Button(action: {
                NSApplication.shared.terminate(nil)
            }, label: {
                Text("Quit Application")
            })
            
        }
        .padding(20)
        
    }
    
    func showImagesCacheFolder() {
        if let imagesFolder = playerManager.imagesFolder {
            NSWorkspace.shared.activateFileViewerSelecting([imagesFolder])
        }
    }
    
}

struct GeneralSettingsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        GeneralSettingsView()
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
