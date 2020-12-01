import SwiftUI
import Combine
import Logging
import SpotifyWebAPI


struct PlayerControlsView: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var sliderValue: CGFloat = 0
    
    @State private var cycleRepeatModeCancellable: AnyCancellable? = nil

    let spotifyGreen = Color(#colorLiteral(red: 0.115554098, green: 0.8118441093, blue: 0.004543508402, alpha: 1))

    let logger = Logger(label: "PlayerControlsView", level: .warning)
    
    var allowedActions: Set<PlaybackActions> {
        return playerManager.currentlyPlayingContext?.allowedActions
            ?? PlaybackActions.allCases
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            PlaybackPositionView()
            
            HStack(spacing: 17) {
            
                    // MARK: Shuffle
                    Button(action: {
                        self.playerManager.shuffleIsOn.toggle()
                        self.playerManager.player.setShuffling?(
                            playerManager.shuffleIsOn
                        )
                    }, label: {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(
                                playerManager.shuffleIsOn ? .green : .primary
                            )
                    })
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 1)
                    .disabled(!allowedActions.contains(.toggleShuffle))
    
                // MARK: Seek Backwards 15 Seconds
                if playerManager.currentTrack?.identifier?.idCategory == .episode {
                    Button(action: seekBackwards15Seconds, label: {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                    })
                    .buttonStyle(PlainButtonStyle())
                }
                else {
                    // MARK: Previous Track
                    Button(action: {
                        self.playerManager.player.previousTrack?()
                    }, label: {
                        Image(systemName: "backward.end.fill")
                    })
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!allowedActions.contains(.skipToPrevious))
                }

                // MARK: Play/Pause
                Button(action: {
                    self.playerManager.player.playpause?()
//                    print(self.playerManager.availableDevices)
                }, label: {
                    if self.playerManager.player.playerState == .playing {
                        Image(systemName: "pause.circle.fill")
                            .resizable()
                    }
                    else {
                        Image(systemName: "play.circle.fill")
                            .resizable()
                    }
                })
                .buttonStyle(PlainButtonStyle())
                .frame(width: 45, height: 45)

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
                    Button(action: {
                        self.playerManager.player.nextTrack?()
                    }, label: {
                        Image(systemName: "forward.end.fill")
                    })
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!allowedActions.contains(.skipToNext))
                }
                
                // MARK: Repeat Mode
                Button(action: cycleRepeatMode, label: repeatView)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 1)
                    .disabled(repeatModeIsDisabled())
                
//                VStack {
//                    // MARK: Available Devices
//                    AvailableDevicesView()
//                        .scaleEffect(1.2)
//                        .padding(.bottom, 2)
//                        .disabled(!allowedActions.contains(.transferPlayback))
//
//                    // MARK: Additional Actions
//                    Button(action: {
//
//                    }, label: {
//                        Image(systemName: "ellipsis")
//                    })
//                    .buttonStyle(PlainButtonStyle())
//                }
                
                
            }
            .font(.largeTitle)
            .padding(.horizontal, 10)
            
            // MARK: Sound Volume
            HStack {
                Image(systemName: "speaker.fill")
                PlayerPositionSliderView(
                    value: $playerManager.soundVolume,
                    isDragging: .constant(false),
                    range: 0...100,
                    knobDiameter: 15,
                    leadingRectangleColor: .green
                )
                Image(systemName: "speaker.wave.3.fill")
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
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
    
    func seekBackwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            self.logger.error("couldn't get player position")
            return
        }
        self.playerManager.setPlayerPosition(
            to: CGFloat(currentPosition - 15)
        )
    }
    
    func seekForwards15Seconds() {
        guard let currentPosition = self.playerManager.player.playerPosition else {
            self.logger.error("couldn't get player position")
            return
        }
        self.playerManager.setPlayerPosition(
            to: CGFloat(currentPosition + 15)
        )
    }
    
    func cycleRepeatMode() {
        self.playerManager.repeatMode.cycle()
        let repeatMode = self.playerManager.repeatMode
        self.cycleRepeatModeCancellable = self.spotify.api
            .setRepeatMode(to: repeatMode)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.logger.error(
                        """
                        couldn't set repeat mode to \(repeatMode.rawValue)": \
                        \(error)
                        """
                    )
                }
            })
    }

    func repeatView() -> AnyView {
        switch playerManager.repeatMode {
            case .off:
                return Image(systemName: "repeat")
                    .font(.title2)
                    .eraseToAnyView()
            case .context:
                return Image(systemName: "repeat")
                    .font(.title2)
                    .foregroundColor(.green)
                    .eraseToAnyView()
            case .track:
                return Image(systemName: "repeat.1")
                    .font(.title2)
                    .foregroundColor(.green)
                    .eraseToAnyView()
        }
    }
    
    func repeatModeIsDisabled() -> Bool {
        let requiredActions: Set<PlaybackActions> = [
            .toggleRepeatContext,
            .toggleRepeatTrack
        ]
        return !requiredActions.isSubset(of: allowedActions)
    }
    
}

struct PlayerControlsView_Previews: PreviewProvider {
    
//    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        
        PlayerView_Previews.previews
        
//        PlayerControlsView()
//            .environmentObject(playerManager.spotify)
//            .environmentObject(playerManager)
//            .frame(width: 200)
        
    }
}
