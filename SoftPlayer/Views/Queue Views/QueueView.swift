import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct QueueView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    var body: some View {
        List {
            ForEach(
//                Array(Self.sampleQueue.enumerated()),
                Array(playerManager.queue.enumerated()),
                id: \.offset
            ) { (offset, item) in
                QueueItemView(item: item)
            }
        }
    }
    
}

extension QueueView {
    
    static let sampleQueue: [PlaylistItem] = [
        .echoesAcousticVersion,
        .joeRogan1536,
        .joeRogan1537,
        .killshot,
        .oceanBloom,
        .samHarris216,
        .samHarris217,
        .track(.comeTogether),
        .track(.because),
        .track(.reckoner),
        .track(.time),
        .track(.theEnd),
        .track(.illWind),
        .track(.odeToViceroy)
    ]
    
}

struct QueueView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        QueueView()
            .frame(
                width: AppDelegate.popoverWidth,
                height: AppDelegate.popoverHeight
            )
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
    
}
