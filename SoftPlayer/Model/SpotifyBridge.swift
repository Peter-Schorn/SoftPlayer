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

class CustomSpotifyApplication {
    
    private let spotifyApplication: SpotifyApplication

    /// If `true`, then all apple events sent via the methods of
    /// `SpotifyApplication` are blocked.
    var blockAppleEvents = false

    init?() {
        if let spotifyApplication = SBApplication(
            bundleIdentifier: "com.spotify.client"
        ) {
            self.spotifyApplication = spotifyApplication
        }
        else {
            return nil
        }
        
    }
    
    func activate() {
        if self.blockAppleEvents { return }
        self.spotifyApplication.activate()
    }

    var isRunning: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.isRunning
    }

    /// The current playing track.
    var currentTrack: SpotifyTrack? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.currentTrack
    }
    
    /// The sound output volume (minimum = 0; maximum = 100).
    var soundVolume: Int? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.soundVolume
    }
    
    /// Is Spotify stopped, paused, or playing?
    var playerState: SpotifyEPlS? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.playerState
    }
    
    /// The player’s position within the currently playing track in seconds.
    var playerPosition: Double? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.playerPosition
    }
    
    /// Is repeating enabled in the current playback context?
    var repeatingEnabled: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.repeatingEnabled
    }
    
    /// Is repeating on or off?
    var repeating: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.repeating
    }
    
    /// enabled in the current playback context?
    var shufflingEnabled: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.shufflingEnabled
    }
    
    /// Is shuffling on or off?
    var shuffling: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.shuffling
    }
    
    /// The name of the application.
    var name: String? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.name
    }
    
    /// Is this the frontmost (active) application?
    var frontmost: Bool? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.frontmost
    }
    
    /// The version of the application.
    var version: String? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.version
    }
    

    /// Skip to the next track.
    func nextTrack() -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.nextTrack?()
    }
    
    /// Skip to the previous track.
    func previousTrack() -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.previousTrack?()
    }
    
    /// Toggle play/pause.
    func playpause() -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.playpause?()
    }
    
    /// Pause playback.
    func pause() -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.pause?()
    }
    
    /// Resume playback.
    func play() -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.play?()
    }
    
    /// Start playback of a track in the given context.
    func playTrack(_ x: String!, inContext: String!) -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.playTrack?(x, inContext: inContext)
    }
    
    /// The sound output volume (minimum = 0; maximum = 100).
    func setSoundVolume(_ soundVolume: Int) -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.setSoundVolume?(soundVolume)
    }
    
    /// The player’s position within the currently playing track in seconds.
    func setPlayerPosition(_ playerPosition: Double) -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.setPlayerPosition?(playerPosition)
    }
    
    /// Is repeating on or off?
    func setRepeating(_ repeating: Bool) -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.setRepeating?(repeating)
    }
    
    /// Is shuffling on or off?
    func setShuffling(_ shuffling: Bool) -> Void? {
        if self.blockAppleEvents { return nil }
        return self.spotifyApplication.setShuffling?(shuffling)
    }

}

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

