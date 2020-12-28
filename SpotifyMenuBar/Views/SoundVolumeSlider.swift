import SwiftUI
import Combine
import SpotifyWebAPI

struct SoundVolumeSlider: View {

    @EnvironmentObject var playerManager: PlayerManager

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "speaker.fill")
            CustomSliderView(
                value: $playerManager.soundVolume,
                isDragging: $playerManager.isDraggingSoundVolumeSlider,
                range: 0...100,
                knobDiameter: 15,
                knobColor: .white,
                leadingRectangleColor: .green,
                onEndedDragging: onEndedDragging
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
    
    func onEndedDragging(_ value: DragGesture.Value) {
        self.playerManager.lastAdjustedSoundVolumeSliderDate = Date()
    }
}

struct SoundVolumeSlider_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
