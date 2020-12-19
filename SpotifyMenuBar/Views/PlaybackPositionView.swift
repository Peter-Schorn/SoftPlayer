import Foundation
import Combine
import SwiftUI

struct PlaybackPositionView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    let timerInterval: Double
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    let noPositionPlaceholder = "- : -"
    
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
                isDragging: $playerManager.playbackPositionViewIsDragging,
                range: 0...duration,
                knobDiameter: 10,
                knobColor: .white,
                knobScaleEffectMagnitude: 1.3,
                leadingRectangleColor: .playbackPositionLeadingRectangle,
                onEndedDragging: { _ in self.updatePlaybackPosition() }
            )
            .padding(.bottom, 5)
            
            HStack {
                Text(formattedPlaybackPosition)
                    .font(.caption)
                Spacer()
                Text(formattedDuration)
                    .font(.caption)
            }
            .padding(.horizontal, 5)
        }
        .onReceive(timer) { _ in
            if self.playerManager.playbackPositionViewIsDragging ||
                    self.playerManager.player.playerState != .playing {
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
    
    var formattedPlaybackPosition: String {
        if self.playerManager.player.playerPosition == nil {
            return self.noPositionPlaceholder
        }
        let formatter: DateComponentsFormatter = duration >= 3600 ?
                .playbackTimeWithHours : .playbackTime
        return formatter.string(from: Double(self.playerManager.playerPosition))
                ?? self.noPositionPlaceholder
    }
    
    var formattedDuration: String {
        if self.playerManager.currentTrack?.duration == nil {
            return self.noPositionPlaceholder
        }
        let formatter: DateComponentsFormatter = duration >= 3600 ?
                .playbackTimeWithHours : .playbackTime
        return formatter.string(from: Double(duration))
                ?? self.noPositionPlaceholder
        
    }
    
    func updatePlaybackPosition() {
        Loggers.soundVolumeAndPlayerPosition.trace(
            """
            updating playback position to \
            \(self.playerManager.playerPosition)
            """
        )
        self.playerManager.player.setPlayerPosition?(
            Double(self.playerManager.playerPosition)
        )
    }
   
}

struct PlayerPositionView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}

