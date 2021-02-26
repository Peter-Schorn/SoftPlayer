import Foundation
import Logging
import os

typealias Logger = Logging.Logger
typealias OSLogger = os.Logger

enum Loggers {
    
    static let playerManager = Logger(
        label: "PlayerManager",
        level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let playerState = Logger(
        label: "PlayerState",
        level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let artwork = Logger(
        label: "Artwork",
        level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )

    static let shuffle = Logger(
        label: "Shuffle",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let repeatMode = Logger(
        label: "RepeatMode",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let availableDevices = Logger(
        label: "AvailableDevices",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let images = Logger(
        label: "Images",
        level: .error,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let syncContext = Logger(
        label: "SyncContext",
        level: .error,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let keyEvent = Logger(
        label: "KeyEvent",
        level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let playlistsScrollView = Logger(
        label: "PlaylistsScrollView",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let playlistCellView = Logger(
        label: "PlaylistCellView",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let touchBarView = Logger(
        label: "TouchBarView",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static let soundVolumeAndPlayerPosition = Logger(
        label: "SoundVolumeAndPlayerPosition",
        level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    
    static func convertToOSLogLevel(_ level: Logger.Level) -> OSLogType {
        switch level {
            case .trace, .notice:
                return .default
            case .info, .warning:
                return .info
            case .debug:
                return .debug
            case .error:
                return .error
            case .critical:
                return .fault
        }
    }

}

struct SpotifyMenuBarLogHandler: LogHandler {
    
    private static var handlerIsInitialized = false
    
    private static let initializeHandlerDispatchQueue = DispatchQueue(
        label: "SpotifyAPILogHandler.initializeHandler"
    )
    
    static func bootstrap(label: String) -> Self {
        return Self.init(label: label, logLevel: .trace)
    }
    
    
    /// A label for the logger.
    let label: String
    
    var _logLevel: Logger.Level

    var logLevel: Logger.Level {
        get {
            #if RELEASE
            return .trace
            #else
            return self._logLevel
            #endif
        }
        set {
            self._logLevel = newValue
        }
    }
    
    var metadata: Logger.Metadata
    
    private let osLogger: OSLogger

    /**
     Creates the logging backend.
     
     - Parameters:
     - label: A label for the logger.
     - logLevel: The log level.
     - metadata: Metadata for this logger.
     */
    init(
        label: String,
        logLevel: Logger.Level,
        metadata: Logger.Metadata = Logger.Metadata()
    ) {
        self.label = label
        self._logLevel = logLevel
        self.metadata = metadata
        self.osLogger = OSLogger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: label
        )
    }
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let logMessage = """
            [\(label): \(level): \(function) line \(line)] \(message)
            """
        print(logMessage)
        let osLogLevel = Loggers.convertToOSLogLevel(level)
        self.osLogger.log(level: osLogLevel, "\(logMessage, privacy: .public)")
    }
    
}
