import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct QueueItemView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let item: PlaylistItem
    let index: Int
    let isSelected: Bool

    @State private var playQueueCancellable: AnyCancellable? = nil

    var artistName: String {
        switch self.item {
            case .track(let track):
                return track.artists?.first?.name ?? ""
            case .episode(let episode):
                return episode.show?.name ?? ""
        }
    }

    var image: Image {
        self.playerManager.queueItemImage(for: self.item)
                ?? Image(.spotifyAlbumPlaceholder)
//        Image(.spiritualArtwork)
    }

    var body: some View {
        Button(action: {
            playerManager.playQueueItem(item)
        }, label: {
            HStack {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(2)
                    .padding(.trailing, 5)
                VStack {
                    HStack {
                        Text(item.name)
                            .lineLimit(2)
                        Spacer()
                    }
                    HStack {
                        Text(artistName)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onDragOptional {
                if let uri = self.item.uri,
                        let url = try? SpotifyIdentifier(uri: uri).url {
                    return NSItemProvider(object: url as NSURL)
                }
                return nil
            }
        })
        .disabled(isSelected)
        .buttonStyle(PlainButtonStyle())
        .contextMenu(menuItems: contextMenu)

    }
    
    func contextMenu() -> some View {
        Button {
            guard let url = self.item.uri.flatMap(URL.init(string:)) else {
                NSSound.beep()
                return
            }
            self.playerManager.openSpotifyDesktopApplication { _, _ in
                NSWorkspace.shared.open(url)
            }
        } label: {
            Text("Open in Spotify")
        }
    }
    
}

struct QueueItemView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        QueueItemView(
            item: PlaylistItem.track(.comeTogether),
            index: 0,
            isSelected: false
        )
        .frame(
            width: AppDelegate.popoverWidth
        )
        .environmentObject(playerManager)
        .environmentObject(playerManager.spotify)
    }

}
