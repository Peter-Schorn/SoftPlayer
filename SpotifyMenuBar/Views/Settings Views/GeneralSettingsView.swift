import SwiftUI
import Combine
import SpotifyWebAPI

struct GeneralSettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Form {
            Button(
                "Show Images Cache Folder",
                action: showImagesCacheFolder
            )
            .disabled(!spotify.isAuthorized)
            
            Text(
                "You can safely remove files from " +
                "this folder to free up space"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
            
            Button(
                "Logout from Spotify",
                action: spotify.api.authorizationManager.deauthorize
            )
            .disabled(!spotify.isAuthorized)
            
            Text(
                "All personal data will be removed"
            )
            .font(.footnote)
            .foregroundColor(.secondary)

            Button("Quit Application") {
                NSApplication.shared.terminate(nil)
            }
            
        }
        .padding(20)
        
    }
    
    func showImagesCacheFolder() {
        if let imagesFolder = playerManager.imagesFolder {
            NSWorkspace.shared.activateFileViewerSelecting([imagesFolder])
        }
    }
    
}

//struct GeneralSettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        GeneralSettingsView()
//    }
//}
