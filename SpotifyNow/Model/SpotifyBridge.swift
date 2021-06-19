import Foundation
import AppKit
import ScriptingBridge
import SpotifyWebAPI

// MARK: SpotifyApplication
@objc public protocol SpotifyApplication: SBApplicationProtocol {
    
    /// The current playing track.
    @objc optional var currentTrack: SpotifyTrack { get }
    
    /// The sound output volume (minimum = 0; maximum = 100).
    @objc optional var soundVolume: Int { get }
    
    /// Is Spotify stopped, paused, or playing?
    @objc optional var playerState: SpotifyEPlS { get }
    
    /// The player’s position within the currently playing track in seconds.
    @objc optional var playerPosition: Double { get }
    
    /// Is repeating enabled in the current playback context?
    @objc optional var repeatingEnabled: Bool { get }
    
    /// Is repeating on or off?
    @objc optional var repeating: Bool { get }
    
    /// Is shuffling enabled in the current playback context?
    @objc optional var shufflingEnabled: Bool { get }
    
    /// Is shuffling on or off?
    @objc optional var shuffling: Bool { get }
    
    /// Skip to the next track.
    @objc optional func nextTrack()
    
    /// Skip to the previous track.
    @objc optional func previousTrack()
    
    /// Toggle play/pause.
    @objc optional func playpause()
    
    /// Pause playback.
    @objc optional func pause()
    
    /// Resume playback.
    @objc optional func play()
    
    /// Start playback of a track in the given context.
    @objc optional func playTrack(_ x: String!, inContext: String!)
    
    /// The sound output volume (minimum = 0; maximum = 100).
    @objc optional func setSoundVolume(_ soundVolume: Int)
    
    /// The player’s position within the currently playing track in seconds.
    @objc optional func setPlayerPosition(_ playerPosition: Double)
    
    /// Is repeating on or off?
    @objc optional func setRepeating(_ repeating: Bool)
    
    /// Is shuffling on or off?
    @objc optional func setShuffling(_ shuffling: Bool)
    
    /// The name of the application.
    @objc optional var name: String { get }
    
    /// Is this the frontmost (active) application?
    @objc optional var frontmost: Bool { get }
    
    /// The version of the application.
    @objc optional var version: String { get }
}

extension SBApplication: SpotifyApplication { }

// MARK: SpotifyTrack
@objc public protocol SpotifyTrack: SBObjectProtocol {
    
    /// The artist of the track.
    @objc optional var artist: String { get }
    
    /// The album of the track.
    @objc optional var album: String { get }
    
    /// The disc number of the track.
    @objc optional var discNumber: Int { get }
    
    /// The length of the track in milliseconds.
    @objc optional var duration: Int { get }
    
    /// The number of times this track has been played.
    @objc optional var playedCount: Int { get }
    
    /// The index of the track in its album.
    @objc optional var trackNumber: Int { get }
    
    /// Is the track starred?
    @objc optional var starred: Bool { get }
    
    /// How popular is this track? 0-100
    @objc optional var popularity: Int { get }
    
    /// The URI of the item.
    @objc optional func id() -> String
    
    /// The name of the track.
    @objc optional var name: String { get }
    
    /// The URL of the track's album cover.
    @objc optional var artworkUrl: String { get }
    
//    /// The property is deprecated and will never be set.
//    /// Use the 'artwork url' instead.
//    @objc optional var artwork: NSImage { get }
    
    /// That album artist of the track.
    @objc optional var albumArtist: String { get }
    
    /// The URL of the track.
    @objc optional var spotifyUrl: String { get }
    
    /// The URL of the track.
    @objc optional func setSpotifyUrl(_ spotifyUrl: String!)
}

extension SpotifyTrack {
    
    var identifier: SpotifyIdentifier? {
        guard let id = self.id?() else {
            return nil
        }
        return try? SpotifyIdentifier(uri: id)
    }

}

extension SBObject: SpotifyTrack { }

// MARK: SpotifyEPlS
@objc public enum SpotifyEPlS : AEKeyword, CustomStringConvertible {
    
    case stopped = 0x6b505353
    case playing = 0x6b505350
    case paused = 0x6b505370
    
    public var description: String {
        switch self {
            case .stopped:
                return "stopped"
            case .playing:
                return "playing"
            case .paused:
                return "paused"
        }
    }
    
}

@objc public protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc public protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: SBApplicationDelegate! { get set }
    @objc optional var isRunning: Bool { get }
}

