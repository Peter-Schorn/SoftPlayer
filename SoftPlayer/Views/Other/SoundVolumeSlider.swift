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
                onEndedDragging: { _ in onEndedDragging() }
            )
            Image(systemName: "speaker.wave.3.fill")
        }
        .onChange(of: playerManager.soundVolume, perform: { newVolume in
            
            let currentVolume = self.playerManager.spotifyApplication?.soundVolume ?? 100
            let intNewVolume = Int(newVolume)
            
            if abs(intNewVolume - currentVolume) >= 2 {
                self.playerManager.spotifyApplication?.setSoundVolume(intNewVolume)
            }
            
        })
    }
    
    func onEndedDragging() {
        self.playerManager.lastAdjustedSoundVolumeSliderDate = Date()
    }
}

struct SoundVolumeSlider_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        SoundVolumeSlider()
            .environmentObject(playerManager)
    }
}
