import SwiftUI

struct PlaylistsScrollViewSkeleton: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var text = ""
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack {
                    TextField("Search", text: $text)
                        .padding()
//                    ForEach(playerManager.playlists, id: \.self) { playlist in
//                        PlaylistsCellView(playlist: playlist)
//                    }
                }
            }
        }
    }
}

struct PlaylistsScrollViewSkeleton_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistsScrollViewSkeleton()
    }
}
