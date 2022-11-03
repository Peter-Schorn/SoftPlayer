import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct GeneralSettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    var body: some View {
        Form {
            
            Picker(
                selection: playerManager.$appearance,
                content: {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.localizedDescription)
                            .tag(appearance)
                        if appearance == .system {
                            Divider()
                        }
                    }
                },
                label: { Text("Appearance:") }
            )
            .frame(width: 200)
            .padding(.bottom, 10)
 
            Button(action: showImagesCacheFolder, label: {
                Text("Show Images Folder")
            })
            Text(
                "You can safely remove files from this folder to free up space"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)
//            .border(Color.green)
            
            
            if spotify.isAuthorized {
                
                Button(action: spotify.api.authorizationManager.deauthorize, label: {
                    Text("Logout from Spotify")
                })
                Text(
                    "All user data will be removed"
                )
                .font(.footnote)
                .foregroundColor(.secondary)
                
            }
            else {
                
                Button(action: spotify.authorize) {
                    // MARK: TODO: Add Cool green color gradient
                    Text("Login to Spotify")
                }
                .padding(.vertical, 5)
                .disabled(spotify.isRetrievingTokens)

            }
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }, label: {
                Text("Quit Application")
            })
            Text(
                "\(KeyboardShortcuts.getShortcut(for: .quit).map(String.init) ?? "")"
            )
            .font(.footnote)
            .foregroundColor(.secondary)
            Spacer()
            let version = AppDelegate.shared.versionBuildIdentifier
            Text("Version: \(version)")
                .font(.callout)
                .foregroundColor(.secondary)
            
        }
        .padding(20)
        .background(
            KeyEventHandler(name: "GeneralSettingsView") { event in
                return self.playerManager.receiveKeyEvent(
                    event,
                    requireModifierKey: true
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        
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
        TabView {
            GeneralSettingsView()
                .environmentObject(playerManager)
                .environmentObject(playerManager.spotify)
                .tabItem { Text("General") }
            
        }
        .padding()
        .frame(width: 400, height: 330)
    }
    
}
