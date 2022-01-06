import SwiftUI
import Combine
import SpotifyWebAPI

struct SettingsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            
            GeneralSettingsView()
                .tabItem { Text("General") }
                .tag(0)
            
            KeyboardShortcutsView()
                .tabItem { Text("Shortcuts") }
                .tag(1)
            
        }
        .padding()
        .frame(
            width:  selectedTab == 0 ? 400 : 450,
            height: selectedTab == 0 ? 300 : 500
        )
        .background(
            KeyEventHandler { event in
                return self.playerManager.receiveKeyEvent(
                    event,
                    requireModifierKey: true
                )
            }
            .touchBar(content: PlayPlaylistsTouchBarView.init)
        )
        .preferredColorScheme(playerManager.colorScheme)
        
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SettingsView()
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
