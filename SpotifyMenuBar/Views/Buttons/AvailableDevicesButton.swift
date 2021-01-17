import SwiftUI
import Combine
import Logging
import SpotifyWebAPI

struct AvailableDevicesButton: View {
    
    @EnvironmentObject var spotify: Spotify
    @EnvironmentObject var playerManager: PlayerManager

    @State private var transferPlaybackCancellable: AnyCancellable? = nil

    @State private var menuItems: [MenuItem] = []

    @State private var menuIsOpen = false

    var body: some View {
//        Menu {
//            if playerManager.availableDevices.isEmpty {
//                Text("No Devices Found")
//            }
//            else {
//                ForEach(playerManager.availableDevices, id: \.id) { device in
//                    Button(action: {
//                        transferPlayback(to: device)
//                    }, label: {
//                        HStack {
//                            Text(device.name)
//                            if device.isActive {
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    })
//                }
//            }
//        } label: {
//            Image(systemName: "hifispeaker.2.fill")
//        }
//        .menuStyle(BorderlessButtonMenuStyle())
//        .disabled(!playerManager.allowedActions.contains(.transferPlayback))
//        .help("Transfer playback to a different device")
//        .scaleEffect(1.2)
//        .frame(width: 33)
        
        AppKitMenu(
            isOpen: $menuIsOpen,
            label: label,
            items: menuItems
        )
        .onTapGesture {
            self.menuIsOpen = true
        }
        .help("Transfer playback to a different device")
        .onChange(of: menuIsOpen) { isOpen in
            if isOpen {
                print("updating player state in response to open menu")
                self.playerManager.updatePlayerState()
            }
        }
        .onChange(of: playerManager.availableDevices) { devices in
            print("onChange of playerManager.availableDevices")
            self.reloadDeviceMenuItems(devices: devices)
        }
        .onAppear {
            print("onAppear")
            self.reloadDeviceMenuItems(
                devices: self.playerManager.availableDevices
            )
        }
        
    }
    
    var label: some View {
        Image(systemName: "hifispeaker.2.fill")
            .font(.title3)
    }

    func reloadDeviceMenuItems(devices: [Device]) {
        let deviceNames = devices.map(\.name)
        print("getting deviceMenuItems: \(deviceNames)")
        
        if !self.playerManager.allowedActions.contains(.transferPlayback) {
            self.menuItems = [
                MenuItem(
                    title: "Transferring playback is not allowed",
                    action: { },
                    enabled: false
                )
            ]
            return
        }

        if devices.isEmpty {
            self.menuItems = [
                MenuItem(
                    title: "No Devices Found",
                    action: { },
                    enabled: false
                )
            ]
            return
        }
        
        self.menuItems = devices.map { device in
            MenuItem(
                title: device.name,
                state: device.isActive ? .on : .off,
                action: { self.transferPlayback(to: device) }
            )
        }
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
        
        self.playerManager.isTransferringPlayback = true
        Loggers.availableDevices.trace("tranferring playback to '\(device.name)'")
        self.transferPlaybackCancellable = self.spotify.api
            .transferPlayback(to: id, play: true)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                self.playerManager.isTransferringPlayback = false
                switch completion {
                    case .finished:
                        self.playerManager.updateSoundVolumeAndPlayerPosition()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.playerManager.updatePlayerState()
                        }
                    case .failure(let error):
                        let alertTitle = "Couldn't Transfer Playback " +
                            #"to "\#(device.name)""#
                        self.playerManager.presentNotification(
                            title: alertTitle,
                            message: error.localizedDescription
                        )
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
