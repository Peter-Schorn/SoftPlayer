import Foundation
import Logging
import os

typealias Logger = Logging.Logger
typealias OSLogger = os.Logger

enum Loggers {
    
    static let general = Logger(
        label: "General",
        level: .warning
    )
    
    static let spotify = Logger(
        label: "spotify",
        level: .warning
    )

    static let playerManager = Logger(
        label: "PlayerManager",
        level: .warning
    )
    
    static let playerState = Logger(
        label: "PlayerState",
        level: .warning
    )
    
    static let artwork = Logger(
        label: "Artwork",
        level: .warning
    )

    static let shuffle = Logger(
        label: "Shuffle",
        level: .warning
    )
    
    static let repeatMode = Logger(
        label: "RepeatMode",
        level: .warning
    )
    
    static let availableDevices = Logger(
        label: "AvailableDevices",
        level: .warning
    )
    
    static let images = Logger(
        label: "Images",
        level: .error
    )
    
    static let syncContext = Logger(
        label: "SyncContext",
        level: .error
    )
    
    static let keyEvent = Logger(
        label: "KeyEvent",
        level: .warning
    )
    
    static let playlistsScrollView = Logger(
        label: "PlaylistsScrollView",
        level: .warning
    )
    
    static let playlistCellView = Logger(
        label: "PlaylistCellView",
        level: .warning
    )
    
    static let touchBarView = Logger(
        label: "TouchBarView",
        level: .warning
    )
    
    static let soundVolumeAndPlayerPosition = Logger(
        label: "SoundVolumeAndPlayerPosition",
        level: .warning
    )
    
}

struct SoftPlayerLogHandler: LogHandler {

    static func convertToOSLogLevel(_ level: Logger.Level) -> OSLogType {
        switch level {
            case .trace:
                return .default
            case .info, .notice, .warning:
                return .info
            case .debug:
                return .debug
            case .error:
                return .error
            case .critical:
                return .fault
        }
    }

    private static var handlerIsInitialized = false
    
    private static let initializeHandlerDispatchQueue = DispatchQueue(
        label: "SpotifyAPILogHandler.initializeHandler"
    )
    
    /// Configures this type as the global logging backend.
    static func bootstrap() {
        LoggingSystem.bootstrap { label in
            Self(label: label, logLevel: .trace)
        }
    }
    
    
    /// A label for the logger.
    let label: String
    
    var _logLevel: Logger.Level

    var logLevel: Logger.Level {
        get {
            #if DEBUG
            return self._logLevel
            #else
            return .trace
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
            [\(label): \(self._logLevel): \(function) line \(line)] \(message)
            """
        #if DEBUG
        print(logMessage)
        #else
        let osLogLevel = Self.convertToOSLogLevel(self._logLevel)
        self.osLogger.log(level: osLogLevel, "\(logMessage, privacy: .public)")
        #endif
    }
    
}

extension SwiftLogNoOpLogHandler {
    
    /// Calls through to `LoggingSystem.bootstrap(_:)` and configures this type
    /// as the global logging backend.
    static func bootstrap() {
        LoggingSystem.bootstrap { _ in
            Self()
        }
    }

}
