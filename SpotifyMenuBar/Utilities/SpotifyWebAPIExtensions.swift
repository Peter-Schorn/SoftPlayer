import Foundation
import Combine
import SpotifyWebAPI

extension SpotifyAPI where AuthorizationManager: SpotifyScopeAuthorizationManager {

    /**
     Makes a call to `availableDevices()` and plays the content on the
     active device if one exists. Else, plays content on the first available
     device.
     
     See [Using the Player Endpoints][1].

     - Parameter playbackRequest: A request to play content.

     [1]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Using-the-Player-Endpoints
     */
    func getAvailableDeviceThenPlay(
        _ playbackRequest: PlaybackRequest
    ) -> AnyPublisher<Void, Error> {
        
        return self.availableDevices().flatMap {
            devices -> AnyPublisher<Void, Error> in
    
            let deviceId: String
            
            // If there is an active device, then it's usually a good idea
            // to use that one.
            if let activeDeviceId = devices.first(where: { device in
                device.isActive && !device.isRestricted && device.id != nil
            })?.id {
                deviceId = activeDeviceId
            }
            // Else, just use the first device with a non-`nil` `id` and that
            // is not restricted. A restricted device will not accept any web
            // API commands.
            else if let nonActiveDeviceId = devices.first(where: { device in
                device.id != nil && !device.isRestricted
            })?.id {
                deviceId = nonActiveDeviceId
            }
            else {
                return SpotifyGeneralError.other(
                    "no active or available devices",
                    localizedDescription: "There are no devices " +
                                          "available to play content on"
                )
                .anyFailingPublisher()
            }
            
            return self.play(playbackRequest, deviceId: deviceId)
    
        }
        .eraseToAnyPublisher()
        
        
        
    }

}

extension CurrentlyPlayingContext {
     
    /// The artist of the currently playing track.
    var artist: Artist? {
        switch self.item {
            case .track(let track):
                return track.artists?.first
            default:
                return nil
        }
    }
    
    /// The show for the currently playing episode.
    var show: Show? {
        switch self.item {
            case .episode(let episode):
                return episode.show
            default:
                return nil
        }
    }
    
    var showOrArtistIdentifier: SpotifyIdentifier? {
        do {
            if let artistURI = self.artist?.uri {
                return try SpotifyIdentifier(uri: artistURI)
            }
            else if let showURI = self.show?.uri {
                return try SpotifyIdentifier(uri: showURI)
            }
            else {
                return nil
            }
            
        } catch {
            print(
                """
                CurrentlyPlayingContext.showOrArtistIdentifier: \
                error: \(error)
                """
            )
            return nil
        }
        
    }

}

extension Track {
    
    /// Returns `true` if the name and artists are the same and if
    /// the duration is similar within a %10 relative tolerance or a
    /// 10 second absolute tolerance.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if let uri = self.uri, let otherURI = other.uri {
            if uri == otherURI { return true }
        }
        
        if self.name != other.name { return false }
        
        let artistNames = Set(self.artists?.map(\.name) ?? [])
        let otherArtistNames = Set(self.artists?.map(\.name) ?? [])
        if artistNames != otherArtistNames {
            return false
        }

        if let duration = self.durationMS, let otherDuration = other.durationMS {
            return duration.isApproximatelyEqual(
                to: otherDuration,
                absoluteTolerance: 10_000,  // 10 seconds
                relativeTolerance: 0.1,
                norm: Double.init
            )
        }
        
        return false
    }

}

extension Episode {
    
    /// Returns `true` if the name and artists are the same and if
    /// the duration is similar within a %10 relative tolerance or a
    /// 10 second absolute tolerance.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if self.uri == other.uri { return true }
     
        if self.name != other.name { return false }
        
        if let show = self.show, let otherShow = other.show {
            if show.name != otherShow.name { return false }
        }
        
        return self.durationMS.isApproximatelyEqual(
            to: other.durationMS,
            absoluteTolerance: 10_000,  // 10 seconds
            relativeTolerance: 0.1,
            norm: Double.init
        )
        
    }
}

extension PlaylistItem {
    
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        switch (self, other) {
            case (.episode(let episode), .episode(let otherEpisode)):
                return episode.isProbablyTheSameAs(otherEpisode)
            case (.track(let track), .track(let othertrack)):
                return track.isProbablyTheSameAs(othertrack)
            default:
                return false
        }

    }

}

extension Collection where Element == SpotifyImage {
    
    /// Images with `nil` for height and/or width are considered to be
    /// the *largest*.
    var smallest: SpotifyImage? {
        
        return self.min { lhs, rhs in
            
            let lhsDimensions = lhs.width.map { width in
                return lhs.height.map { height in
                    width * height
                }
            } as? Int
            
            let rhsDimensions = rhs.width.map { width in
                return rhs.height.map { height in
                    width * height
                }
            } as? Int
            
            switch (lhsDimensions, rhsDimensions) {
                case (nil, .some(_)):
                    return false
                case (.some(_), nil):
                    return true
                case (.some(let lhs), .some(let rhs)):
                    return lhs < rhs
                default:
                    return false

            }
            
        }

    }


}
