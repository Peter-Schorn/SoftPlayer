import SwiftUI

struct LibrarySegmentedControl: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify
    
    var libraryPage: Binding<LibraryPage> {
        Binding(
            get: {
                self.playerManager.libraryPage
            },
            set: { newValue in
                
                if newValue.index <= LibraryPage.albums.index,
                        self.playerManager.libraryPage == .playlists {
                    self.playerManager.libraryPageTransition = .asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    )
                }
                else {
                    self.playerManager.libraryPageTransition = .asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    )
                }

                self.playerManager.libraryPage = newValue
            }
        )
        
    }

    var body: some View {
        Picker("", selection: libraryPage) {

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
