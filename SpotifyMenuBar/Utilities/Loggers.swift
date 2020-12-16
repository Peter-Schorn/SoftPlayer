import Foundation
import Logging
import os

public typealias Logger = Logging.Logger
public typealias OSLogger = os.Logger

enum Loggers {
    
    static let shuffle = Logger(
        label: "Shuffle", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let repeatMode = Logger(
        label: "RepeatMode", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let availableDevices = Logger(
        label: "AvailableDevices", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let playerManager = Logger(
        label: "PlayerManager", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let images = Logger(
        label: "Images", level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let syncContext = Logger(
        label: "SyncContext", level: .error,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let keyEvent = Logger(
        label: "KeyEvent", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let playlistsScrollView = Logger(
        label: "PlaylistsScrollView", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let playlistCellView = Logger(
        label: "PlaylistCellView", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let touchBarView = Logger(
        label: "TouchBarView", level: .warning,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let soundVolumeAndPlayerPosition = Logger(
        label: "SoundVolumeAndPlayerPosition", level: .trace,
        factory: SpotifyMenuBarLogHandler.bootstrap
    )
    static let playerState = Logger(
        label: "PlayerState", level: .trace,
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

public struct SpotifyMenuBarLogHandler: LogHandler {
    
    private static var handlerIsInitialized = false
    
    private static let initializeHandlerDispatchQueue = DispatchQueue(
        label: "SpotifyAPILogHandler.initializeHandler"
    )
    
    public static func bootstrap(label: String) -> Self {
        return Self.init(label: label, logLevel: .trace)
    }
    
    
    /// A label for the logger.
    public let label: String
    
    public var logLevel: Logger.Level
    
    public var metadata = Logger.Metadata()
    
    private let osLogger: OSLogger

    /**
     Creates the logging backend.
     
     - Parameters:
     - label: A label for the logger.
     - logLevel: The log level.
     - metadata: Metadata for this logger.
     */
    public init(
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
    
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return metadata[metadataKey]
        }
        set {
            metadata[metadataKey] = newValue
        }
    }
    
    public func log(
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
