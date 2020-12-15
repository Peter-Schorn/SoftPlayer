import Foundation
import Logging

enum Loggers {
    
    static let shuffle = Logger(
        label: "ShuffleButton", level: .warning
    )
    static let repeatMode = Logger(
        label: "RepeatButton", level: .warning
    )
    static let availableDevices = Logger(
        label: "AvailableDevicesView", level: .trace
    )
    static let playerManager = Logger(
        label: "PlayerManager", level: .warning
    )
    static let images = Logger(
        label: "Images", level: .error
    )
    static let syncContext = Logger(
        label: "SyncContext", level: .error
    )
    static let keyEvent = Logger(
        label: "KeyEvent", level: .trace
    )

}
