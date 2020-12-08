import Foundation
import SwiftUI
import Combine
import ScriptingBridge
import Logging
import SpotifyWebAPI

class PlayerManager: ObservableObject {

    let spotify: Spotify
    
    // MARK: Published Properties
    /// Retrieved from the Spotify desktop application using AppleScript.
    @Published var currentTrack: SpotifyTrack? = nil
    
    /// Retrieved from the Spotify web API.
    @Published var currentlyPlayingContext: CurrentlyPlayingContext? = nil
    
    /// The image for the album/show of the currently playing
    /// track/episode.
    @Published var artworkImage = Image(.spotifyAlbumPlaceholder)
    
    /// Devices with `nil` for `id` and/or are restricted are filtered out.
    @Published var availableDevices: [Device] = []

    @Published var playlists: [Playlist<PlaylistsItemsReference>] = []
    @Published var playlistImages: [String: Image] = [:]
    
    /// The most recently played playlists will appear first.
    @Published var playlistsSortedByLastPlayedDate: [Playlist<PlaylistsItemsReference>] = []
    
    /// The playlists that items were most recently added to will appear first.
    @Published var playlistsSortedByLastAddedDate: [Playlist<PlaylistsItemsReference>] = []
    
    /// The playlists that are **owned** by the current user. These are the
    /// playlists that tracks and episodes can be added to.
    @Published var currentUserPlaylists: [Playlist<PlaylistsItemsReference>] = []
    
    @Published var shuffleIsOn = false
    @Published var repeatMode = RepeatMode.off
    @Published var playerPosition: CGFloat = 0
    @Published var soundVolume: CGFloat = 100
    
    var allowedActions: Set<PlaybackActions> {
        return self.currentlyPlayingContext?.allowedActions
            ?? PlaybackActions.allCases
    }
    
    private var _currentUser: SpotifyUser? = nil
    private var currentUserPublisher: AnyPublisher<SpotifyUser, Never>? = nil
    var currentUser: Future<SpotifyUser, Never> {
        Future { promise in
            if let currentUser = self._currentUser {
                promise(.success(currentUser))
            }
            else {
                self.retrieveCurrentUserCancellable =
                    self.retrieveCurrentUser().sink { currentUser in
                        promise(.success(currentUser))
                    }
            }
        }
    }
    
    private let playlistsLastPlayedDatesKey = "playlistsLastPlayedDate"
    private let playlistsLastAddedDatesKey = "playlistsLastPlayedDate"
    
    /// The dates that the playlists were last played.
    var playlistsLastPlayedDates: [String: Date] {
        get {
            return UserDefaults.standard.dictionary(
                forKey: playlistsLastPlayedDatesKey
            ) as? [String: Date] ?? [:]
        }
        set {
            UserDefaults.standard.setValue(
                newValue,
                forKey: playlistsLastPlayedDatesKey
            )
        }
    }
    
    /// The dates that items were last added to the playlists.
    var playlistsLastAddedDates: [String: Date] {
        get {
            return UserDefaults.standard.dictionary(
                forKey: playlistsLastAddedDatesKey
            ) as? [String: Date] ?? [:]
        }
        set {
            UserDefaults.standard.setValue(
                newValue,
                forKey: playlistsLastAddedDatesKey
            )
        }
    }
    
    // MARK: Publishers
    
    /// `PlayerView` displays an alert when this subject emits.
    let alertSubject = PassthroughSubject<String, Never>()
    
    let artworkURLDidChange = PassthroughSubject<Void, Never>()
    
    /// Emits when the popover is about to be shown.
    let popoverWillShow = PassthroughSubject<Void, Never>()

    /// A publisher that emits when the Spotify player state changes.
    let playerStateDidChange = DistributedNotificationCenter
        .default().publisher(for: .spotifyPlayerStateDidChange)

    
    let player: SpotifyApplication = SBApplication(
        bundleIdentifier: "com.spotify.client"
    )!
    
    private var previousArtworkURL: String?
    
    // MARK: Cancellables
    private var cancellables: Set<AnyCancellable> = []
    private var retrieveAvailableDevicesCancellable: AnyCancellable? = nil
    private var loadArtworkImageCancellanble: AnyCancellable? = nil
    private var retrieveCurrentlyPlayingContextCancellable: AnyCancellable? = nil
    private var retrievePlaylistsCancellable: AnyCancellable? = nil
    private var retrieveCurrentUserCancellable: AnyCancellable? = nil
    private var retrieveCurrentUserPlaylistsCancellable: AnyCancellable? = nil
    
    let logger = Logger(label: "PlayerManager", level: .notice)
    
    init(spotify: Spotify) {
        
        self.spotify = spotify
        self.previousArtworkURL = nil
        
        self.playerStateDidChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                self.logger.trace(
                    "received player state did change notification"
                )
                if self.spotify.isAuthorized {
                    self.updatePlayerState()
                }
            })
            .store(in: &cancellables)
        
        self.artworkURLDidChange
            .sink(receiveValue: self.loadArtworkImage)
            .store(in: &cancellables)
        
        self.popoverWillShow.sink {
            if self.spotify.isAuthorized {
                self.updatePlayerState()
                self.retrievePlaylists()
            }
        }
        .store(in: &cancellables)
        
        self.spotify.$isAuthorized.sink { isAuthorized in
            if isAuthorized {
                self.updatePlayerState()
                self.retrievePlaylists()
            }
        }
        .store(in: &cancellables)

        self.spotify.api.authorizationManager.didDeauthorize
            .receive(on: RunLoop.main)
            .sink {
                self._currentUser = nil
                self.currentUserPublisher = nil
                self.playlistsLastPlayedDates = [:]
                self.playlistsLastAddedDates = [:]
            }
            .store(in: &cancellables)
        
        if self.spotify.isAuthorized {
            self.updatePlayerState()
        }
    }
    
    func updatePlayerState() {
        self.logger.trace("update player state")
        self.retrieveCurrentlyPlayingContext()
        self.retrieveAvailableDevices()
        self.currentTrack = self.player.currentTrack
        self.shuffleIsOn = player.shuffling ?? false
        let newSoundVolume = CGFloat(self.player.soundVolume ?? 100)
        if abs(newSoundVolume - self.soundVolume) >= 2 {
            self.soundVolume = newSoundVolume
            self.logger.trace("sound volume: \(soundVolume) to \(newSoundVolume)")
        }
        if let playerPosition = self.player.playerPosition {
            self.logger.trace("new player position: \(playerPosition)")
            self.playerPosition = CGFloat(playerPosition)
        }
//        self.logger.trace(
//            "player state updated to '\(self.currentTrack?.name ?? "nil")'"
//        )
        if self.currentTrack?.artworkUrl != self.previousArtworkURL {
//            self.logger.trace(
//                """
//                artworkURL changed from \(self.previousArtworkURL ?? "nil") \
//                to \(self.currentTrack?.artworkUrl ?? "nil")
//                """
//            )
            self.artworkURLDidChange.send()
        }
        self.previousArtworkURL = self.player.currentTrack?.artworkUrl
    }
    
    /// Loads the image from the artwork URL of the current track.
    func loadArtworkImage() {
        guard let url = self.currentTrack?.artworkUrl
                .map(URL.init(string:)) as? URL else {
            self.logger.warning(
                "no artwork URL or couldn't convert from String"
            )
            self.artworkImage = Image(.spotifyAlbumPlaceholder)
            return
        }
//        self.logger.trace("loading artwork image from '\(url)'")
        self.loadArtworkImageCancellanble = URLSession.shared
            .dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.logger.error(
                            "couldn't load artwork image: \(error)"
                        )
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                },
                receiveValue: { data, response in
                    if let nsImage = NSImage(data: data) {
                        
                        self.artworkImage = Image(nsImage: nsImage)
                    }
                    else {
                        self.logger.error("couldn't convert data to image")
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                }
            )
    }
    
    func setPlayerPosition(to position: CGFloat) {
        self.player.setPlayerPosition?(Double(position))
        self.playerPosition = position
    }
    
    func retrieveAvailableDevices() {
        self.retrieveAvailableDevicesCancellable = self.spotify.api
            .availableDevices()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.logger.error(
                            "couldn't retreive available devices: \(error)"
                        )
                    }
                },
                receiveValue: { devices in
                    self.availableDevices = devices
                        .filter { $0.id != nil && !$0.isRestricted }
//                    self.logger.trace(
//                        "available devices: \(self.availableDevices)"
//                    )
                }
            )
    }
    
    /// Retrieves the currently playing context and sets the repeat state
    /// and whether play/pause is disabled.
    func retrieveCurrentlyPlayingContext() {
        
        self.retrieveCurrentlyPlayingContextCancellable =
            self.spotify.api.currentPlayback(market: "from_token")
                .receive(on: RunLoop.main)
                .handleAuthenticationError(spotify: self.spotify)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.logger.error(
                                "couldn't get currently playing context: \(error)"
                            )
                        }
                    },
                    receiveValue: self.updateCurrentlyPlayingContext(_:)
                )
        
    }
    
    private func updateCurrentlyPlayingContext(
        _ context: CurrentlyPlayingContext?
    ) {
        
        guard let context = context else { return }
        
        self.logger.trace("updating currently playing context")
        self.currentlyPlayingContext = context
        let allowedActions = context.allowedActions.map(\.rawValue)
        self.logger.notice(
            "\nALLOWED ACTIONS: \(allowedActions)\n"
        )
        self.repeatMode = context.repeatState
        
    }
    
    private func retrieveCurrentUser() -> AnyPublisher<SpotifyUser, Never> {
        
        if let currentUserPublisher = self.currentUserPublisher {
            self.logger.notice("using previous current user publisher")
            return currentUserPublisher
        }
        
        let currentUserPublisher = self.spotify.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .catch { error -> Empty<SpotifyUser, Never> in
                self.logger.error(
                    "couldn't retrieve current user: \(error)"
                )
                return Empty()
            }
            .handleEvents(
                receiveOutput: { currentUser in
                    self.logger.notice("received current user")
                    self._currentUser = currentUser
                },
                receiveCompletion: { _ in
                    self.currentUserPublisher = nil
                }
            )
            .share()
            .eraseToAnyPublisher()
        
        return currentUserPublisher
    }
    
    /// Retreives the user's playlists.
    func retrievePlaylists() {
        
        let retrievePlaylistsPublisher = self.spotify.api
            .currentUserPlaylists(limit: 50)
            .extendPages(self.spotify.api)
//            .handleEvents(receiveOutput: { page in
//                self.logger.trace(
//                    "received playlist page at offset \(page.offset)"
//                )
//            })
            .collect()
            .map { $0.flatMap(\.items) }
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .catch { error -> Empty<[Playlist<PlaylistsItemsReference>], Never> in
                self.logger.error(
                    "couldn't retrieve playlists: \(error)"
                )
                return Empty()
            }
        
        self.retrievePlaylistsCancellable = Publishers.Zip(
            currentUser, retrievePlaylistsPublisher
        )
        .sink { currentUser, playlists in
            self.playlists = playlists
            self.currentUserPlaylists = self.playlists.filter { playlist in
                playlist.owner?.uri == currentUser.uri
            }
            self.retrievePlaylistImages()
            self.updatePlaylistsSortedByLastPlayedDate()
            self.updatePlaylistsSortedByLastAddedDate()
        }
           
    }
    
    func retrievePlaylistImages() {
        for playlist in self.playlists {
            guard self.playlistImages[playlist.uri] == nil else {
                continue
            }
            self.spotify.api.playlistImage(playlist)
                .flatMap { images -> AnyPublisher<Image, Error> in
                    guard let image = images.largest else {
                        self.logger.warning(
                            "images array was empty for '\(playlist.name)'"
                        )
                        return Empty().eraseToAnyPublisher()
                    }
                    return image.load()
                }
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            self.logger.error(
                                "couldn't retrieve playlist image: \(error)"
                            )
                        }
                    },
                    receiveValue: { image in
                        self.playlistImages[playlist.uri] = image
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// Re-sorts the playlists by last played date.
    func updatePlaylistsSortedByLastPlayedDate() {
        self.logger.notice("updatePlaylistsSortedByLastPlayedDate")
        DispatchQueue.global().async {
            let sortedPlaylists = self.playlists.sorted { lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsDate = self.playlistsLastPlayedDates[lhs.uri]
                let rhsDate = self.playlistsLastPlayedDates[rhs.uri]
                switch (lhsDate, rhsDate) {
                    case (.some(let lhsDate), .some(let rhsDate)):
                        return lhsDate > rhsDate
                    case (.some(_), nil):
                        return true
                    default:
                        return false
                }

            }
            DispatchQueue.main.async {
                self.playlistsSortedByLastPlayedDate = sortedPlaylists
            }
        }
    }

    /// Re-sorts the playlists by the last date items were added to them.
    func updatePlaylistsSortedByLastAddedDate() {
        self.logger.notice("updatePlaylistsSortedByLastAddedDate")
        DispatchQueue.global().async {
            let sortedPlaylists = self.currentUserPlaylists.sorted { lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsDate = self.playlistsLastAddedDates[lhs.uri]
                let rhsDate = self.playlistsLastAddedDates[rhs.uri]
                switch (lhsDate, rhsDate) {
                    case (.some(let lhsDate), .some(let rhsDate)):
                        return lhsDate > rhsDate
                    case (.some(_), nil):
                        return true
                    default:
                        return false
                }
            }
            DispatchQueue.main.async {
                self.playlistsSortedByLastAddedDate = sortedPlaylists
            }
        }
    }

}
