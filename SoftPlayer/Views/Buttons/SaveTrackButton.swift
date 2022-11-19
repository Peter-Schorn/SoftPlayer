import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

struct SaveTrackButton: View {

    @EnvironmentObject var playerManager: PlayerManager

    let debugIsShowing: Bool

    init(debugIsShowing: Bool = false) {
        self.debugIsShowing = debugIsShowing
    }
     
    var helpText: Text {
        let shortcutName = KeyboardShortcuts.getShortcut(for: .likeTrack)
            .map { " \($0)"} ?? ""
        if self.playerManager.currentTrackIsSaved {
            return Text("Remove from Liked Songs\(shortcutName)")
        }
        else {
            return Text("Add to Liked Songs\(shortcutName)")
        }
    }

    var body: some View {
        if playerManager.currentTrack?.identifier?.idCategory == .track ||
                debugIsShowing {
            HeartButton(
                isHearted: $playerManager.currentTrackIsSaved,
                action: didTap
            )
            .help(helpText)
            .aspectRatio(1, contentMode: .fit)
        }
    }
    
    func didTap() {
        self.playerManager.addOrRemoveCurrentTrackFromSavedTracks()
    }
    
}

struct SaveTrackButton_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SaveTrackButton(debugIsShowing: true)
            .padding(50)
            .frame(width: 200, height: 200)
            .environmentObject(playerManager)
            .environmentObject(playerManager.spotify)
    }
}
