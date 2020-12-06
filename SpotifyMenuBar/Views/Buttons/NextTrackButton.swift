import SwiftUI
import Combine
import SpotifyWebAPI

struct NextTrackButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
//    @State private var seekForwardTimer = <#value#>
    
    var body: some View {
        
        if playerManager.currentTrack?.identifier?.idCategory == .episode {
            // MARK: Seek Forwards 15 Seconds
            Button(action: seekForwards15Seconds, label: {
                Image(systemName: "goforward.15")
                    .font(.title)
            })
            .buttonStyle(PlainButtonStyle())
        }
        else {
            // MARK: Next Track
            
            Image(systemName: "forward.end.fill")
                .gesture(
                    LongPressGesture()
                        .onChanged { x in
                            print("onchanged: \(x)")
                        }
                )
                .onTapGesture {
                    self.playerManager.player.nextTrack?()
                }
                .disabled(!playerManager.allowedActions.contains(.skipToNext))
            
        }
    }
    
    func seekForwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            print("NextTrackButton: couldn't get player position")
            return
        }
        self.playerManager.setPlayerPosition(
            to: CGFloat(currentPosition + 15)
        )
    }
    
}

struct NextTrackButton_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
