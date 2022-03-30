import SwiftUI
import Combine
import SpotifyWebAPI

struct SettingsView: View {
    
    enum Tab {
        case general
        case keyboardShortcuts
    }

    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var selectedTab = Tab.general

    var body: some View {
        TabView(selection: $selectedTab) {
            
            GeneralSettingsView()
                .tabItem { Text("General") }
                .tag(Tab.general)
            
            KeyboardShortcutsView()
                .tabItem { Text("Shortcuts") }
                .tag(Tab.keyboardShortcuts)
            
        }
        .padding()
        .frame(
            width:  selectedTab == .general ? 400 : 450,
            height: selectedTab == .general ? 300 : 520
        )
        .background(
            KeyEventHandler(name: "SettingsView") { event in
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
