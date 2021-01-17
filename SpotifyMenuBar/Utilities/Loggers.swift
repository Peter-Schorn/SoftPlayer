import Foundation
import Logging
import os

typealias Logger = Logging.Logger
typealias OSLogger = os.Logger

enum Loggers {
    
    static let playerManager = Logger.appInit(
        label: "PlayerManager",
        level: .trace
    )
    
    static let playerState = Logger.appInit(
        label: "PlayerState",
        level: .trace
    )
    
    static let artwork = Logger.appInit(
        label: "Artwork",
        level: .trace
    )

    static let shuffle = Logger.appInit(
        label: "Shuffle",
        level: .warning
    )
    
    static let repeatMode = Logger.appInit(
        label: "RepeatMode",
        level: .warning
    )
    
    static let availableDevices = Logger.appInit(
        label: "AvailableDevices",
        level: .trace
    )
    
    static let images = Logger.appInit(
        label: "Images",
        level: .error
    )
    
    static let syncContext = Logger.appInit(
        label: "SyncContext",
        level: .error
    )
    
    static let keyEvent = Logger.appInit(
        label: "KeyEvent",
        level: .trace
    )
    
    static let playlistsScrollView = Logger.appInit(
        label: "PlaylistsScrollView",
        level: .warning
    )
    
    static let playlistCellView = Logger.appInit(
        label: "PlaylistCellView",
        level: .warning
    )
    
    static let touchBarView = Logger.appInit(
        label: "TouchBarView",
        level: .warning
    )
    
    static let soundVolumeAndPlayerPosition = Logger.appInit(
        label: "SoundVolumeAndPlayerPosition",
        level: .warning
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

extension Logger {
    
    /// The standard initializer for making loggers for this app.
    static func appInit(
        label: String,
        level: Logger.Level
    ) -> Self {
        
        return Logger(
            label: label,
            level: .traceOnReleaseOr(level),
            factory: SpotifyMenuBarLogHandler.bootstrap(label:)
        )

    }

}

extension Logger.Level {
    
    static func traceOnReleaseOr(_ level: Self) -> Self {
        #if RELEASE
        return .trace
        #else
        return level
        #endif
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
    
    var logLevel: Logger.Level
    
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
        self.logLevel = logLevel
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
