import SwiftUI

struct LibrarySegmentedControl: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    var body: some View {
        Picker("", selection: playerManager.$libraryPage) {

            Image(systemName: "music.note.list")
                .help(Text("Playlists"))
                .tag(LibraryPage.playlists)
        
            Image(systemName: "square.stack.fill")
                .help(Text("Albums"))
                .tag(LibraryPage.albums)
            
            Image(systemName: "text.insert")
                .help(Text("Queue"))
                .tag(LibraryPage.queue)
            
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 5)
        .frame(width: 150)
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
