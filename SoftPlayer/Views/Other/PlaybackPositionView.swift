import Foundation
import Combine
import SwiftUI

struct PlaybackPositionView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    let timerInterval: Double
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    var duration: CGFloat {
        return CGFloat((playerManager.currentTrack?.duration ?? 1) / 1000)
    }
    
    init() {
        self.timerInterval = 0.5
        self.timer = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect()
    }
    
    var body: some View {
        VStack(spacing: -5) {
            CustomSliderView(
                value: $playerManager.playerPosition,
                isDragging: $playerManager.isDraggingPlaybackPositionView,
                range: 0...duration,
                knobDiameter: 10,
                knobColor: .white,
                knobScaleEffectMagnitude: 1.3,
                knobAnimation: .linear(duration: 0.1),
                leadingRectangleColor: .playbackPositionLeadingRectangle,
                onEndedDragging: { _ in self.updatePlaybackPosition() }
            )
            .padding(.bottom, 5)
            
            HStack {
                Text(playerManager.formattedPlaybackPosition)
                    .font(.caption)
                Spacer()
                Text(playerManager.formattedDuration)
                    .font(.caption)
            }
            .padding(.horizontal, 5)
        }
        .onReceive(timer) { _ in
            
            guard AppDelegate.shared.popover.isShown else {
                return
            }

            if self.playerManager.isDraggingPlaybackPositionView ||
                self.playerManager.spotifyApplication?.playerState != .playing {
                return
            }
            if playerManager.playerPosition + CGFloat(timerInterval) >= duration {
                playerManager.playerPosition = duration
                self.playerManager.updatePlayerState()
            }
            else {
                playerManager.playerPosition += CGFloat(timerInterval)
            }
        }
    }
    
    func updatePlaybackPosition() {
        self.playerManager.lastAdjustedPlayerPositionDate = Date()
        Loggers.soundVolumeAndPlayerPosition.trace(
            """
            updating playback position to \
            \(self.playerManager.playerPosition)
            """
        )
        self.playerManager.spotifyApplication?.setPlayerPosition?(
            Double(self.playerManager.playerPosition)
        )
    }
   
}

struct PlayerPositionView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}

