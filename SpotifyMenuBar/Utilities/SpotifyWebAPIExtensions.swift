import Foundation
import Combine
import SpotifyWebAPI

extension SpotifyAPI where AuthorizationManager: SpotifyScopeAuthorizationManager {

    /**
     Makes a call to `availableDevices()` and plays the content on the
     active device if one exists. Else, plays content on the first available
     device.
     
     See [Using the Player Endpints][1].

     - Parameter playbackRequest: A request to play content.

     [1]: https://github.com/Peter-Schorn/SpotifyAPI/wiki/Using-the-Player-Endpoints
     */
    func getAvailableDeviceThenPlay(
        _ playbackRequest: PlaybackRequest
    ) -> AnyPublisher<Void, Error> {
        
        return self.availableDevices().flatMap {
            devices -> AnyPublisher<Void, Error> in
    
            let deviceId: String
            
            // If there is an actice device, then it's usually a good idea
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
                return SpotifyLocalError.other(
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
    
    var artist: Artist? {
        switch self.item {
            case .track(let track):
                return track.artists?.first
            default:
                return nil
        }
    }
    
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
            if let artist = self.artist, let uri = artist.uri {
                return try SpotifyIdentifier(uri: uri)
            }
            else if let show = self.show {
                return try SpotifyIdentifier(uri: show.uri)
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
    /// the duration is similar within a %10 relative tolerance and a
    /// 10 second absolute tolerance.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if let uri = self.uri, let otherURI = other.uri {
            if uri == otherURI { return true }
        }
        
        if self.name != other.name { return false }
        let artistNames = Set(self.artists.map { $0.map(\.name) } ?? [])
        let otherArtistNames = Set(self.artists.map { $0.map(\.name) } ?? [])
        if artistNames != otherArtistNames {
            return false
        }

        if let duration = self.durationMS, let otherDuration = other.durationMS {
            return Double(duration).isApproximatelyEqual(
                to: Double(otherDuration),
                // the duration is in milliseconds
                absoluteTolerance: 10_000,
                relativeTolerance: 0.1
            )
        }
        
        return false
    }

}

extension Episode {
    
    /// Returns `true` if the name and artists are the same and if
    /// the duration is similar within a %10 relative tolerance and a
    /// 10 second absolute tolerance.
    func isProbablyTheSameAs(_ other: Self) -> Bool {
        
        if self.uri == other.uri { return true }
     
        if self.name != other.name { return false }
        if let show = self.show, let otherShow = other.show {
            if show.name != otherShow.name { return false }
        }
        
        return Double(self.durationMS).isApproximatelyEqual(
            to: Double(other.durationMS),
            // the duration is in milliseconds
            absoluteTolerance: 10_000,
            relativeTolerance: 0.1
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
