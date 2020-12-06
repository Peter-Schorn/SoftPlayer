import SwiftUI
import Combine
import SpotifyWebAPI

struct SoundVolumeSlider: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "speaker.fill")
            CustomSliderView(
                value: $playerManager.soundVolume,
                isDragging: .constant(false),
                range: 0...100,
                knobDiameter: 15,
                leadingRectangleColor: .green
            )
            Image(systemName: "speaker.wave.3.fill")
        }
        .onChange(of: playerManager.soundVolume, perform: { newVolume in
            let currentVolume = CGFloat(
                self.playerManager.player.soundVolume ?? 100
            )
            if abs(newVolume - currentVolume) >= 2 {
                self.playerManager.player.setSoundVolume?(Int(newVolume))
            }
        })
        
    }
}

struct SoundVolumeSlider_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
