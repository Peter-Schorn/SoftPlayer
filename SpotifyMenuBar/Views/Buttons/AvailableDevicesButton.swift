import SwiftUI
import Combine
import Logging
import SpotifyWebAPI

struct AvailableDevicesButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager
    
    @State private var alertIsPresented = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var transferPlaybackCancellable: AnyCancellable? = nil
    
    var body: some View {
        Menu {
            if playerManager.availableDevices.isEmpty {
                Text("No Devices Found")
            }
            else {
                ForEach(playerManager.availableDevices, id: \.id) { device in
                    Button(action: {
                        transferPlayback(to: device)
                    }, label: {
                        HStack {
                            Text(device.name)
                            if device.isActive {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }
        } label: {
            Image(systemName: "hifispeaker.2.fill")
        }
        .menuStyle(BorderlessButtonMenuStyle())
        .disabled(!playerManager.allowedActions.contains(.transferPlayback))
        .help("Transfer playback to a different device")
        .scaleEffect(1.2)
        .frame(width: 33)
        .alert(isPresented: $alertIsPresented, content: {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage)
            )
        })
        
    }
    
    func transferPlayback(to device: Device) {
        guard let id = device.id else {
            Loggers.availableDevices.warning(
                "device id was nil for '\(device.name)'"
            )
            return
        }
        
        if device.isActive {
            Loggers.availableDevices.notice(
                "'\(device.name)' is already active; ignoring transfer request"
            )
            return
        }
        
        Loggers.availableDevices.trace("tranferring playback to '\(device.name)'")
        self.transferPlaybackCancellable = self.spotify.api
            .transferPlayback(to: id, play: true)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.playerManager.retrieveAvailableDevices()
                        }
                    case .failure(let error):
                        self.alertTitle = "Couldn't Transfer Playback " +
                            #"to "\#(device.name)""#
                        self.alertMessage = error.localizedDescription
                        self.alertIsPresented = true
                        Loggers.availableDevices.error(
                            "\(alertTitle): \(error)"
                        )
                }
            })
    }
    
}

struct AvailableDevicesButton_Previews: PreviewProvider {
    
    static let playerManager = PlayerManager(spotify: Spotify())
    
    static var previews: some View {
        AvailableDevicesButton()
            .environmentObject(playerManager.spotify)
            .environmentObject(playerManager)
            .padding(20)
        
        PlayerView_Previews.previews

    }
}
