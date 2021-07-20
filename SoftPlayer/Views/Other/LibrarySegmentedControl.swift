import SwiftUI

struct LibrarySegmentedControl: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    var body: some View {
        Picker(
//            selection: playerManager.$libraryTab,
            selection: playerManager.$libraryPage,
            label: EmptyView()
        ) {
            Text("Playlists")
                .tag(0)
        
            Text("Albums")
                .tag(1)
            
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 5)
    }
}

struct LibrarySegmentedControl_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        LibrarySegmentedControl()
            .frame(width: AppDelegate.popoverWidth, height: 350)
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
