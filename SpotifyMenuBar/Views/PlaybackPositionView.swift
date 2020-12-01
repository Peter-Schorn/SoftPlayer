import Foundation
import Combine
import SwiftUI

struct PlaybackPositionView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var isDragging = false
    
    let timerStep: Double
    let timer: Publishers.Autoconnect<Timer.TimerPublisher>
    
    var duration: CGFloat {
        return CGFloat((playerManager.currentTrack?.duration ?? 1) / 1000)
    }
    
    init() {
        self.timerStep = 0.5
        self.timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
    }
    
    var body: some View {
        VStack(spacing: -5) {
            PlayerPositionSliderView(
                value: $playerManager.playerPosition,
                isDragging: $isDragging,
                range: 0...duration,
                knobDiameter: 10,
                leadingRectangleColor: .gray,
                onEnded: { _ in self.updatePlaybackPosition() }
            )
            .padding(.bottom, 5)
            
            HStack {
                Text(formattedPlaybackPosition)
                    .font(.caption)
                Spacer()
                Text(formattedDuration)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
//        .padding(.bottom, 5)
        .onReceive(timer) { _ in
            if self.isDragging ||
                    playerManager.player.playerState != .playing {
                return
            }
            if playerManager.playerPosition + CGFloat(timerStep) >= duration {
                playerManager.playerPosition = duration
                self.playerManager.updatePlayerState()
            }
            else {
                playerManager.playerPosition += CGFloat(timerStep)
            }
        }
    }
    
    var formattedPlaybackPosition: String {
        if playerManager.currentTrack?.duration == nil {
            return "- : -"
        }
        let timeString: String?
        if playerManager.playerPosition >= 3600 {
            timeString = DateComponentsFormatter.playbackTimeWithHours
                .string(from: Double(playerManager.playerPosition))
        }
        else {
            timeString = DateComponentsFormatter.playbackTime
                .string(from: Double(playerManager.playerPosition))
        }
        return timeString ?? ""
    }
    
    var formattedDuration: String {
        if playerManager.currentTrack?.duration == nil {
            return "- : -"
        }
        let timeString: String?
        if duration >= 3600 {
            timeString = DateComponentsFormatter.playbackTimeWithHours
                .string(from: Double(duration))
        }
        else {
            timeString = DateComponentsFormatter.playbackTime
                .string(from: Double(duration))
        }
        return timeString ?? ""
    }
    
    func updatePlaybackPosition() {
        print(
            "updating playback position to " +
            "\(self.playerManager.playerPosition)"
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

