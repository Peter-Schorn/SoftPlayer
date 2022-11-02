import Foundation
import Combine
import SwiftUI

struct PlaybackPositionView: View {
    
    @EnvironmentObject var playerManager: PlayerManager
    
    let timerInterval: Double
    let timer: Timer.TimerPublisher
    @State private var timerCancellable: Cancellable? = nil
    
    var duration: CGFloat {
        return CGFloat((playerManager.currentTrack?.duration ?? 1) / 1000)
    }
    
    init() {
        self.timerInterval = 0.5
        self.timer = Timer.publish(
            every: timerInterval,
            on: .main,
            in: .common
        )
        
        if AppDelegate.shared.popover.isShown {
            self.timerCancellable = self.timer.connect()
        }

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
        .onReceive(playerManager.popoverWillShow) {
            self.timerCancellable = self.timer.connect()
        }
        .onReceive(playerManager.popoverDidClose) {
            self.timerCancellable?.cancel()
        }
        .onReceive(timer) { _ in
            
            guard AppDelegate.shared.popover.isShown &&
                    playerManager.spotify.isAuthorized &&
                    !playerManager.isShowingLibraryView else {
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
        Loggers.soundVolumeAndPlayerPosition.trace(
            """
            updating playback position to \
            \(self.playerManager.playerPosition)
            """
        )
        self.playerManager.spotifyApplication?.setPlayerPosition(
            Double(self.playerManager.playerPosition)
        )
        self.playerManager.lastAdjustedPlayerPositionDate = Date()
    }
   
}

struct PlayerPositionView_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())

    static var previews: some View {
        PlaybackPositionView()
            .environmentObject(playerManager)
    }
}



