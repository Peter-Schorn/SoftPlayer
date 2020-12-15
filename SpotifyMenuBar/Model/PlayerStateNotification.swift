import Foundation

/// The userInfo dictionary from the notification that Spotify
/// posts when the player state changes.
struct PlayerStateNotification {
    
    /// Whether content is playing or paused.
    let state: State?
    
    /// The currend playback position in **seconds**.
    let playbackPosition: Double?
    
    /// The duration of the track/episode in **milliseconds**.
    let durationMS: Int?
    
    let artistName: String?
    
    let albumName: String?

    /// The name of the artist of the album that the track appears on.
    let albumArtistName: String?

    /// The name of the track/episode.
    let itemName: String?
    
    /// The URI for the track/episode
    let uri: String?
    
    let popularity: Int?
    
    let hasArtwork: Bool
    
    let playcount: Int?
    
    let trackNumber: Int?
    
    let discNumber: Int?
    
    /// The location of the track in the file system if this is a local track.
    let location: URL?
    
    init?(userInfo: [AnyHashable : Any]?) {
        guard let userInfo = userInfo else { return nil }
        
        self.state = ((userInfo["Player State"] as? String)
                        .map(State.init(rawValue:)) as? State)
        self.playbackPosition = userInfo["Playback Position"] as? Double
        self.durationMS = userInfo["Duration"] as? Int
        
        if let artistName = userInfo["Artist"] as? String, !artistName.isEmpty {
            self.artistName = artistName
        }
        else {
            self.artistName = nil
        }
        
        if let albumName = userInfo["Album"] as? String, !albumName.isEmpty {
            self.albumName = albumName
        }
        else {
            self.albumName = nil
        }
        
        if let albumArtistName = userInfo["Album Artist"] as? String,
                !albumArtistName.isEmpty {
            self.albumArtistName = albumArtistName
            
        }
        else {
            self.albumArtistName = nil
        }
        
        if let itemName = userInfo["Name"] as? String, !itemName.isEmpty {
            self.itemName = itemName
        }
        else {
            self.itemName = nil
        }
        
        if let uri = userInfo["Track ID"] as? String, !uri.isEmpty {
            self.uri = uri
        }
        else {
            self.uri = nil
        }
        
        self.popularity = userInfo["Popularity"] as? Int
        self.hasArtwork = userInfo["Has Artwork"] as? Bool ?? false
        self.playcount = userInfo["Play Count"] as? Int
        self.trackNumber = userInfo["Track Number"] as? Int
        self.discNumber = userInfo["Disc Number"] as? Int

        self.location = (userInfo["Location"] as? String)
            .map(URL.init(fileURLWithPath:))
        
        
        
    }
    
    /// Whether content is playing or paused.
    enum State: String, CaseIterable {
        case playing
        case paused
        case stopped
        case fastForwarding
        case rewinding
        
        init?(rawValue: String) {
            let lowerCasedRawValue = rawValue.lowercased()
            for state in Self.allCases {
                if state.rawValue == lowerCasedRawValue {
                    self = state
                    return
                }
            }
            return nil
        }
    }
    
}
