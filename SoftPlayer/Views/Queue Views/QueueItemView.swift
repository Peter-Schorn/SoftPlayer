import Foundation
import Combine
import SwiftUI
import SpotifyWebAPI
import KeyboardShortcuts

struct QueueItemView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    @EnvironmentObject var spotify: Spotify

    let item: PlaylistItem

    @State private var playQueueCancellable: AnyCancellable? = nil

    var artistName: String? {
        switch self.item {
            case .track(let track):
                return track.artists?.first?.name
            case .episode(let episode):
                return episode.show?.name
        }
    }

    var body: some View {
        Button(action: self.play, label: {
            VStack {
                HStack {
                    Text(item.name)
                        .lineLimit(2)
                    Spacer()
                }
                HStack {
                    Text(artistName ?? "")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(PlainButtonStyle())

    }
    
    func play() {
        
        let errorTitle = String.localizedStringWithFormat(
            NSLocalizedString(
                "Couldn't Play \"%@\"",
                comment: "Couldn't Play [queue item name]"
            ),
            self.item.name
        )
        
        guard let uri = self.item.uri else {
            Loggers.queue.error(
                "\(errorTitle): no URI"
            )
            let message = "Missing data"
            self.playerManager.notificationSubject.send(
                AlertItem(title: errorTitle, message: message)
            )
            return
        }
        
        let playbackRequest: PlaybackRequest
        
        if let contextURI = self.playerManager.currentlyPlayingContext?
                .context?.uri {
            playbackRequest = PlaybackRequest(
                context: .contextURI(contextURI),
                offset: .uri(uri)
            )
        }
        else {
            playbackRequest = PlaybackRequest(uri)
        }

        Loggers.queue.trace(
            "will play '\(self.item.name)'; playbackRequest: \(playbackRequest)"
        )

        self.playQueueCancellable = self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            Loggers.queue.trace(
                                "play '\(self.item.name)' finished normally"
                            )
                        case .failure(let error):
                            Loggers.queue.error(
                                "\(errorTitle): \(error)"
                            )
                            let message = error.customizedLocalizedDescription
                            self.playerManager.notificationSubject.send(
                                AlertItem(title: errorTitle, message: message)
                            )
                            
                    }
                },
                receiveValue: {
                    
                }
            )
        

    }
}

struct QueueItemView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        QueueItemView(item: PlaylistItem.track(.comeTogether))
            .frame(
                width: AppDelegate.popoverWidth
//                height: AppDelegate.popoverHeight
            )
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }

}
