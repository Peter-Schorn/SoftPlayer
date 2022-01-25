import SwiftUI

struct LibrarySegmentedControl: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    var body: some View {
        Picker(
            selection: playerManager.$libraryPage,
            label: EmptyView()
        ) {

            Image(systemName: "music.note.list")
                .tag(LibraryPage.playlists)
                .help(Text("Playlists"))
        
            Image(systemName: "square.stack.fill")
                .tag(LibraryPage.albums)
                .help(Text("Albums"))
            
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 5)
        .frame(width: 100)
    }
}

struct LibrarySegmentedControl_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        LibrarySegmentedControl()
            .padding()
            .frame(
                width: AppDelegate.popoverWidth,
                height: 350,
                alignment: .top
            )
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
