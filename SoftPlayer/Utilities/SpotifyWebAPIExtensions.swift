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
                    localizedDescription: NSLocalizedString(
                        "There are no devices available to play content on",
                        comment: ""
                    )
                )
                .anyFailingPublisher()
            }
            
            return self.play(playbackRequest, deviceId: deviceId)
    
        }
        .eraseToAnyPublisher()
        
    }

    /// Retrieves the name of the given playlist.
    func playlistName(
        _ playlist: SpotifyURIConvertible, market: String? = nil
    ) -> AnyPublisher<String, Error> {
    
        return self.filteredPlaylist(
            playlist,
            filters: "name",
            additionalTypes: [],
            market: market
        )
        .decodeSpotifyObject(SimplePlaylist.self)
        .map(\.name)
        .eraseToAnyPublisher()

    }

}

struct SimplePlaylist: Codable, Hashable {
    
    let name: String
    
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
            Loggers.general.trace(
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
            
            let lhsDimensions = lhs.width.flatMap { width in
                return lhs.height.map { height in
                    width * height
                }
            }
            
            let rhsDimensions = rhs.width.flatMap { width in
                return rhs.height.map { height in
                    width * height
                }
            }
            
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

extension RepeatMode {
    
    var localizedDescription: String {
        return NSLocalizedString(
            self.rawValue,
            comment: "RepeatMode.rawValue"
        )
    }

}

// MARK: - Spanish -

extension Device {
    
    static let spanishDevices: [Self] = [
        .pedroComputer,
        .pedroIphone
    ]

    static let pedroComputer = Self(
        id: "",
        isActive: true,
        isPrivateSession: false,
        isRestricted: false,
        name: "MacBook Pro de Pedro",
        type: .computer,
        volumePercent: nil
    )

    static let pedroIphone = Self(
        id: "",
        isActive: false,
        isPrivateSession: false,
        isRestricted: false,
        name: "iPhone de Pedro",
        type: .smartphone,
        volumePercent: nil
    )
    
}

extension Playlist where Items == PlaylistItemsReference {
    
    init(
        name: String,
        id: String,
        owner: SpotifyUser? = nil
    ) {
        
        let identifier = SpotifyIdentifier(
            id: id, idCategory: .playlist
        )

        self.init(
            name: name,
            items: .init(href: nil, total: 0),
            owner: owner,
            isCollaborative: false,
            snapshotId: "",
            href: .example,
            id: id,
            uri: identifier.uri,
            images: []
        )
    }

    static let spanishPlaylists: [Self] = [
        .luisMiguel,
        .losÉxitosDeRock,
        .losMejoresDeGustavoCerati,
        .elRockClásico,
        .esteEsEnriqueIglesias,
        .shakira,
        .tusCancionesMasPopulares,
        .elBluesClásicos,
        .alejandroSanz
    ]

    static let luisMiguel = Self(
        name: "Luis Miguel",
        id: "01KRdno32jt1vmG7s5pVFg",
        owner: .peter
    )

    static let losÉxitosDeRock = Self(
        name: "Los éxitos de rock",
        id: "5XjvJgo6aUOF6mwtJIKOZr"
    )
    
    static let losMejoresDeGustavoCerati = Self(
        name: "Los mejores de Gustavo Cerati",
        id: "37i9dQZF1EJJh1E5HEdm0o"
    )
    
    static let elRockClásico = Self(
        name: "El rock clásico",
        id: "37i9dQZF1EUMDoJuT8yJsl",
        owner: .peter
    )
    
    static let esteEsEnriqueIglesias = Self(
        name: "Este es Enrique Iglesias",
        id: "0ijeB2eFmJL1euREk6Wu6C"
    )
    
    static let shakira = Self(
        name: "Shakira",
        id: "2EgZjzog2eSfApWQHZVn6t",
        owner: .peter
    )
    
    static let tusCancionesMasPopulares = Self(
        name: "Tus canciones mas populares",
        id: "5MlKAGFZNoN2d0Up8sQc0N"
    )
    
    static let elBluesClásicos = Self(
        name: "El blues clásicos",
        id: "33yLOStnp2emkEA76ew1Dz",
        owner: .peter
    )
    
    static let alejandroSanz = Self(
        name: "Alejandro Sanz",
        id: "37i9dQZF1DX3zc219hYxy3",
        owner: .peter
    )
    
}

extension SpotifyUser {
    
    static let peter = Self.init(
        displayName: nil,
        uri: "spotify:user:petervschorn",
        id: "petervschorn",
        images: nil,
        href: .example,
        allowsExplicitContent: true,
        explicitContentSettingIsLocked: false
    )

}

public struct VaporServerError: LocalizedError, Codable {
    
    /// Always set to `true` to indicate that the JSON payload represents an
    /// error response.
    public let error: Bool

    /// The reason for the error.
    public let reason: String
    
    
    public var errorDescription: String? {
        self.reason
    }

}

extension VaporServerError: CustomStringConvertible {
    
    public var description: String {
        return """
            \(Self.self)(reason: "\(self.reason)")
            """
    }
    
}

extension VaporServerError {
    
    public static func decodeFromNetworkResponse(
        data: Data, response: HTTPURLResponse
    ) -> Error? {
        
        guard (400..<600).contains(response.statusCode) else {
            return nil
        }
        
        return try? JSONDecoder().decode(
            Self.self, from: data
        )
        
    }
    
}
