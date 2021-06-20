import Foundation
import SwiftUI
import Combine
import ScriptingBridge
import Logging
import SpotifyWebAPI
import KeyboardShortcuts

class PlayerManager: ObservableObject {

    let spotify: Spotify
    
    @AppStorage("onlyShowMyPlaylists") var onlyShowMyPlaylists = false
    
    @Published var isShowingPlaylistsView = false
    @Published var isDraggingPlaybackPositionView = false
    @Published var isDraggingSoundVolumeSlider = false
    
    // MARK: - Player State -
    
    /// Retrieved from the Spotify desktop application using AppleScript.
    @Published var currentTrack: SpotifyTrack? = nil
    
    var albumArtistTitle: String {
        let albumName = self.currentTrack?.album
        if let artistName = self.currentTrack?.artist, !artistName.isEmpty {
            if let albumName = albumName, !albumName.isEmpty {
                return "\(artistName) - \(albumName)"
            }
            return artistName
        }
        if let albumName = albumName, !albumName.isEmpty {
            return albumName
        }
        return ""
    }
    
    @Published var shuffleIsOn = false
    @Published var repeatMode = RepeatMode.off
    @Published var playerPosition: CGFloat = 0
    @Published var soundVolume: CGFloat = 100
    
    /// The last date that the user adjusted the player position from this
    /// app.
    var lastAdjustedPlayerPositionDate: Date? = nil
    
    /// The last date that the user adjusted the sound volume from this
    /// app.
    var lastAdjustedSoundVolumeSliderDate: Date? = nil
    
    
    /// Retrieved from the Spotify web API.
    @Published var currentlyPlayingContext: CurrentlyPlayingContext? = nil

    var syncedCurrentlyPlayingContext: Future<CurrentlyPlayingContext?, Never> {
        return Future { promise in
            if self.isUpdatingCurrentlyPlayingContext {
                Loggers.syncContext.trace(
                    "Future: Will wait for context update"
                )
                self.didUpdateCurrentlyPlayingContextCancellable =
                    self.didUpdateCurrentlyPlayingContext.sink {
                        let context = self.currentlyPlayingContext
                        let name = context?.item?.name ?? "nil"
                        Loggers.syncContext.trace(
                            """
                            FUTURE: received didUpdateCurrentlyPlayingContext: \
                            \(name)
                            """
                        )
                        promise(.success(context))
                    }
            }
            else {
                Loggers.syncContext.trace("Future: NOT updating context")
                promise(.success(self.currentlyPlayingContext))
            }
        }
    }
    
    /// The image for the album/show of the currently playing
    /// track/episode.
    @Published var artworkImage = Image(.spotifyAlbumPlaceholder)
    
    // MARK: - Devices -

    /// Devices with `nil` for `id` and/or are restricted are filtered out.
    @Published var availableDevices: [Device] = []
    
    /// Whether or not there is an in-progress request to transfer playback to
    /// a different device.
    @Published var isTransferringPlayback = false
    
    var activeDevice: Device? {
        return self.availableDevices.first { device in
            device.isActive
        }
    }

    var allowedActions: Set<PlaybackActions> {
        return self.currentlyPlayingContext?.allowedActions
            ?? PlaybackActions.allCases
    }
    
    @Published var currentUser: SpotifyUser? = nil

    var imagesFolder: URL? {
        guard let applicationSupportFolder = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            Loggers.playerManager.error(
                "couldn't get application support directory"
            )
            return nil
        }
        return applicationSupportFolder
            .appendingPathComponent(
                "images", isDirectory: true
            )
    }

    // MARK: - Playlists -

    @Published var playlists: [Playlist<PlaylistItemsReference>] = []
    
    /// Sorted based on the last time they were played or an item was added to
    /// them, whichever was later.
    @Published var playlistsSortedByLastModifiedDate:
        [Playlist<PlaylistItemsReference>] = []
    
    private let playlistsLastModifiedDatesKey = "playlistsLastModifiedDates"
    
    /// The dates that playlists were last played or items were
    /// added to them.
    var playlistsLastModifiedDates: [String: Date] {
        get {
            return UserDefaults.standard.dictionary(
                forKey: playlistsLastModifiedDatesKey
            ) as? [String: Date] ?? [:]
        }
        set {
            UserDefaults.standard.setValue(
                newValue,
                forKey: playlistsLastModifiedDatesKey
            )
        }
    }
    
    // MARK: - Notification -
    
    let notificationSubject = PassthroughSubject<(title: String, message: String), Never>()
    
    // MARK: - Publishers -
    
    let artworkURLDidChange = PassthroughSubject<Void, Never>()
    
    /// Emits when the popover is about to be shown.
    let popoverWillShow = PassthroughSubject<Void, Never>()
    
    /// Emits after the popover dismisses.
    let popoverDidClose = PassthroughSubject<Void, Never>()

    /// A publisher that emits when the Spotify player state changes.
    let playerStateDidChange = DistributedNotificationCenter
        .default().publisher(for: .spotifyPlayerStateDidChange)

    let player: SpotifyApplication = SBApplication(
        bundleIdentifier: "com.spotify.client"
    )!
    
    private var previousArtworkURL: String? = nil
    private var isUpdatingCurrentlyPlayingContext = false
    private var didUpdateCurrentlyPlayingContext = PassthroughSubject<Void, Never>()
    
    // MARK: - Cancellables -
    private var cancellables: Set<AnyCancellable> = []
    private var retrieveAvailableDevicesCancellable: AnyCancellable? = nil
    private var loadArtworkImageCancellable: AnyCancellable? = nil
    private var retrieveCurrentlyPlayingContextCancellable: AnyCancellable? = nil
    private var retrievePlaylistsCancellable: AnyCancellable? = nil
    private var retrieveCurrentUserCancellable: AnyCancellable? = nil
    private var didUpdateCurrentlyPlayingContextCancellable: AnyCancellable? = nil
    private var openArtistOrShowCancellable: AnyCancellable? = nil
    private var cycleRepeatModeCancellable: AnyCancellable? = nil
    private var updateSoundVolumeAndPlayerPositionCancellable: AnyCancellable? = nil
    
    init(spotify: Spotify) {
        
        self.spotify = spotify
        
        self.playerStateDidChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: { _ in
                Loggers.playerManager.trace(
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
            }
            self.updateSoundVolumeAndPlayerPositionCancellable = Timer.publish(
                every: 2, on: .main, in: .common
            )
            .autoconnect()
            .sink { _ in
                if !self.isShowingPlaylistsView && self.spotify.isAuthorized {
                    Loggers.soundVolumeAndPlayerPosition.trace("timer fired")
                    self.updateSoundVolumeAndPlayerPosition(fromTimer: true)
                    self.retrieveAvailableDevices()
                }
            }
        }
        .store(in: &cancellables)
        
        self.popoverDidClose.sink {
            Loggers.playerManager.trace("popoverDidDismiss")
            self.updateSoundVolumeAndPlayerPositionCancellable = nil
            self.updatePlaylistsSortedByLastModifiedDate()
        }
        .store(in: &cancellables)
        
        self.spotify.$isAuthorized.sink { isAuthorized in
            Loggers.playerManager.notice(
                "spotify.$isAuthorized.sink: \(isAuthorized)"
            )
            if isAuthorized {
                self.retrieveCurrentUser()
                self.updatePlayerState()
                self.retrievePlaylists()
            }
        }
        .store(in: &cancellables)

        self.spotify.api.authorizationManager.didDeauthorize
            .receive(on: RunLoop.main)
            .sink {
                self.currentlyPlayingContext = nil
                self.availableDevices = []
                self.currentUser = nil
                self.playlistsLastModifiedDates = [:]
                self.playlists = []
                self.playlistsSortedByLastModifiedDate = []
                self.removeImagesCache()
            }
            .store(in: &cancellables)

    }
    
    // MARK: - Playback State -
    
    func updatePlayerState() {
        
        Loggers.playerState.trace("will update player state")
        self.retrieveAvailableDevices()

        if self.isTransferringPlayback {
            Loggers.artwork.notice(
                "not updating player state because isTransferringPlayback"
            )
            return
        }
        
        self.updateSoundVolumeAndPlayerPosition()
        self.retrieveCurrentlyPlayingContext()
        Loggers.playerState.trace(
            """
            player state updated from '\(self.currentTrack?.name ?? "nil")' \
            to '\(self.player.currentTrack?.name ?? "nil")'
            """
        )
        self.currentTrack = self.player.currentTrack
        self.shuffleIsOn = player.shuffling ?? false
        Loggers.shuffle.trace("self.shuffleIsOn = \(self.shuffleIsOn)")
        
        Loggers.artwork.trace("URL: '\(self.currentTrack?.artworkUrl ?? "nil")'")
        if self.currentTrack?.artworkUrl != self.previousArtworkURL {
            Loggers.artwork.trace(
                """
                artworkURL changed from \(self.previousArtworkURL ?? "nil") \
                to \(self.currentTrack?.artworkUrl ?? "nil")
                """
            )
            self.artworkURLDidChange.send()
        }
        self.previousArtworkURL = self.player.currentTrack?.artworkUrl
    }
    
    func updateSoundVolumeAndPlayerPosition(fromTimer: Bool = false) {
        Loggers.soundVolumeAndPlayerPosition.trace("")
        
        // MARK: Sound Volume
        if let intSoundVolume = self.player.soundVolume {
            if self.isDraggingSoundVolumeSlider {
                return
            }
            if let lastAdjusted = self.lastAdjustedSoundVolumeSliderDate,
               lastAdjusted.addingTimeInterval(3) >= Date() {
                Loggers.soundVolumeAndPlayerPosition.notice(
                    "sound volume was adjusted three seconds ago or less"
                )
                return
            }
            
            let newSoundVolume = CGFloat(intSoundVolume)
            if abs(newSoundVolume - self.soundVolume) >= 2 {
                Loggers.soundVolumeAndPlayerPosition.trace(
                    """
                changed sound volume from \(soundVolume) to \
                \(newSoundVolume)"
                """
                )
                self.soundVolume = newSoundVolume
            }
        }
        else {
            Loggers.soundVolumeAndPlayerPosition.warning(
                "couldn't get sound volume"
            )
        }
        
        // MARK: Player Position
        if let playerPosition = self.player.playerPosition,
                !self.isDraggingPlaybackPositionView {
            // if the player position was adjusted by the user three seconds ago
            // or less, then don't update it here.
            if let lastAdjusted = self.lastAdjustedPlayerPositionDate,
                   fromTimer,
                   lastAdjusted.addingTimeInterval(3) >= Date() {
                Loggers.soundVolumeAndPlayerPosition.notice(
                    "player position was adjusted three seconds ago or less"
                )
                return
            }
            let cgPlayerPosition = CGFloat(playerPosition)
            if abs(cgPlayerPosition - self.playerPosition) > 1 {
                
                Loggers.soundVolumeAndPlayerPosition.trace(
                    """
                    changed player position from \(playerPosition) to \
                    \(cgPlayerPosition)"
                    """
                )
                self.playerPosition = cgPlayerPosition
            }
            
        }

    }
    
    /// Loads the image from the artwork URL of the current track.
    func loadArtworkImage() {
        guard let url = self.currentTrack?.artworkUrl
                .flatMap(URL.init(string:)) else {
            Loggers.playerManager.warning(
                "no artwork URL or couldn't convert from String"
            )
            self.artworkImage = Image(.spotifyAlbumPlaceholder)
            return
        }
//        Loggers.playerManager.trace("loading artwork image from '\(url)'")
        self.loadArtworkImageCancellable = URLSession.shared
            .dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "couldn't load artwork image: \(error)"
                        )
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                },
                receiveValue: { data, response in
                    if let nsImage = NSImage(data: data) {
                        // MARK: Successfully Receive Image
                        self.artworkImage = Image(nsImage: nsImage)
                    }
                    else {
                        Loggers.playerManager.error("couldn't convert data to image")
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
//        Loggers.playerManager.trace("")
        self.retrieveAvailableDevicesCancellable = self.spotify.api
            .availableDevices()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "couldn't retrieve available devices: \(error)"
                        )
                    }
                },
                receiveValue: { devices in
                    let newDevices = devices.filter {
                        $0.id != nil && !$0.isRestricted
                    }
                    Loggers.availableDevices.trace(
                        """
                        will update availableDevices from \
                        \(self.availableDevices.map(\.name)) to \
                        \(newDevices.map(\.name))
                        """
                    )
                    self.availableDevices = newDevices
                    
                }
            )
    }
    
    /// Retrieves the currently playing context and sets the repeat state
    /// and whether play/pause is disabled.
    func retrieveCurrentlyPlayingContext(level: Int = 1) {
        
        if level >= 5 {
            Loggers.syncContext.trace("level \(level) >= 5")
            self.currentlyPlayingContext = nil
            self.isUpdatingCurrentlyPlayingContext = false
            return
        }
        
        // This delay is necessary because this request is made right
        // after playback has changed. Without this delay, the web API
        // may return information for the previous playback.
        self.isUpdatingCurrentlyPlayingContext = true
        Loggers.syncContext.trace(
            "isUpdatingCurrentlyPlayingContext = true; level: \(level)"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.retrieveCurrentlyPlayingContextCancellable =
                self.spotify.api.currentPlayback()
                .receive(on: RunLoop.main)
                .handleAuthenticationError(spotify: self.spotify)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            Loggers.playerManager.error(
                                "couldn't get currently playing context: \(error)"
                            )
                            self.presentNotification(
                                title: "Couldn't retrieve playback state",
                                message: error.customizedLocalizedDescription
                            )
                            self.currentlyPlayingContext = nil
                            self.isUpdatingCurrentlyPlayingContext = false
                        }
                    },
                    receiveValue: { context in
                        guard let uriFromContext = context?.item?.uri,
                              let uriFromAppleScript = self.player.currentTrack?.id?()
                        else {
                            return
                        }
                        let contextName = context?.item?.name ?? "nil"
                        let appleScriptName = self.player.currentTrack?.name ?? "nil"
                        if uriFromContext == uriFromAppleScript {
                            Loggers.syncContext.trace(
                                """
                                uriFromContext == uriFromAppleScript
                                '\(contextName)' == '\(appleScriptName)'
                                """
                            )
                            self.receiveCurrentlyPlayingContext(context)
                        }
                        else {
                            let asyncDelay = 0.2 * Double(level) * 2
                            Loggers.syncContext.warning(
                                """
                                uriFromContext != uriFromAppleScript
                                \(uriFromContext) != \(uriFromAppleScript)
                                '\(contextName)' != '\(appleScriptName)'
                                asyncDelay: \(asyncDelay)
                                """
                            )
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + asyncDelay
                            ) {
                                self.retrieveCurrentlyPlayingContext(
                                    level: level + 1
                                )
                            }
                        }
                    }
                )
        }
        
    }
    
    // MARK: - Player Controls -
    
    func cycleRepeatMode() {
        self.repeatMode.cycle()
        self.cycleRepeatModeCancellable = self.spotify.api
            .setRepeatMode(to: self.repeatMode)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                let repeatModeString = self.repeatMode.rawValue
                switch completion {
                    case .failure(let error):
                        let alertTitle =
                            "Couldn't set repeat mode to \(repeatModeString)"
                        self.presentNotification(
                            title: alertTitle,
                            message: error.customizedLocalizedDescription
                        )
                        Loggers.repeatMode.error(
                            "RepeatButton: \(alertTitle): \(error)"
                        )
                    case .finished:
                        Loggers.repeatMode.trace(
                            "cycleRepeatMode completion for \(repeatModeString)"
                        )
                }
                
            })
    }
    
    func toggleShuffle() {
        
        self.shuffleIsOn.toggle()
        Loggers.shuffle.trace(
            "will set shuffle to \(self.shuffleIsOn)"
        )
        self.player.setShuffling?(
            self.shuffleIsOn
        )
    }
    
    /// If a track is playing, skips to the previous track;
    /// if an episode is playing, seeks backwards 15 seconds.
    func previousTrackOrSeekBackwards() {
        if self.currentTrack?.identifier?.idCategory == .episode {
            self.seekBackwards15Seconds()
        }
        else {
            self.skipToPreviousTrack()
        }
    }

    /// If a track is playing, skips to the next track;
    /// if an episode is playing, seeks forwards 15 seconds.
    func nextTrackOrSeekForwards() {
        if self.currentTrack?.identifier?.idCategory == .episode {
            self.seekForwards15Seconds()
        }
        else {
            self.skipToNextTrack()
        }
    }
    
    func skipToPreviousTrack() {
        Loggers.playerState.trace("")
        self.player.previousTrack?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updatePlayerState()
        }
    }
    
    func seekBackwards15Seconds() {
        guard let currentPosition = self.player.playerPosition else {
            Loggers.soundVolumeAndPlayerPosition.error(
                "couldn't get player position"
            )
            return
        }
        let newPosition = max(0, currentPosition - 15)
        self.setPlayerPosition(to: CGFloat(newPosition))
    }
    
    func playPause() {
        self.player.playpause?()
    }

    func skipToNextTrack() {
        Loggers.playerState.trace("")
        self.player.nextTrack?()
    }
    
    func seekForwards15Seconds() {
        guard let currentPosition = self.player.playerPosition else {
            Loggers.soundVolumeAndPlayerPosition.error(
                "couldn't get player position"
            )
            return
        }
        let newPosition: Double
        if let duration = self.currentTrack?.duration {
            newPosition = (currentPosition + 15)
                .clamped(to: 0...Double(duration / 1000))
        }
        else {
            newPosition = currentPosition + 15
        }
        self.setPlayerPosition(to: CGFloat(newPosition))
    }

    // MARK: - Playlists -
    
    func playPlaylist(
        _ playlist: Playlist<PlaylistItemsReference>
    ) -> AnyPublisher<Void, Error> {
        
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist),
            offset: nil
        )
        
        self.playlistsLastModifiedDates[playlist.uri] = Date()
        
        return self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .eraseToAnyPublisher()
    }
    
    /// Retrieve the current user's playlists.
    func retrievePlaylists() {
        
        self.retrievePlaylistsCancellable = self.spotify.api
            .currentUserPlaylists(limit: 50)
            .extendPagesConcurrently(self.spotify.api)
            .collectAndSortByOffset()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    Loggers.playerManager.trace(
                        "retrievePlaylists completion: \(completion)"
                    )
                    guard case .failure(let error) = completion else {
                        return
                    }
                    let title = "Couldn't Retrieve Playlists"
                    Loggers.playerManager.error(
                        "\(title): \(error)"
                    )
                    self.presentNotification(
                        title: title,
                        message: error.customizedLocalizedDescription
                    )
                    
                },
                receiveValue: { playlists in
                    self.playlists = playlists
                    self.retrievePlaylistImages()
                    self.updatePlaylistsSortedByLastModifiedDate()
                }
            )

    }

    /// Re-sorts the playlists by the last date they were played or items
    /// were added to them, whichever was more recent.
    func updatePlaylistsSortedByLastModifiedDate() {
        Loggers.playerManager.notice(
            "updatePlaylistsSortedByLastPlayedOrLastAddedDate"
        )
        DispatchQueue.global().async {
            let sortedPlaylists = self.playlists.enumerated().sorted {
                lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsDate = self.playlistsLastModifiedDates[lhs.1.uri]
                let rhsDate = self.playlistsLastModifiedDates[rhs.1.uri]
                return self.areInDecreasingOrderByDateThenIncreasingOrderByIndex(
                    lhs: (index: lhs.offset, date: lhsDate),
                    rhs: (index: rhs.offset, date: rhsDate)
                )
            }
            .map(\.1)
            
            DispatchQueue.main.async {
                self.playlistsSortedByLastModifiedDate = sortedPlaylists
            }
        }
    }
    
    // MARK: - User -
    
    func retrieveCurrentUser() {
        
        self.retrieveCurrentUserCancellable = self.spotify.api
            .currentUserProfile()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        let title = "Couldn't Retrieve User Profile"
                        Loggers.playerManager.error(
                            "\(title): \(error)"
                        )
                        self.presentNotification(
                            title: title,
                            message: error.customizedLocalizedDescription
                        )
                    }
                },
                receiveValue: { user in
                    Loggers.playerManager.notice(
                        "received current user: \(user)"
                    )
                    self.currentUser = user
                }
            )

    }

    // MARK: - Images -
    
    func retrievePlaylistImages() {
        for playlist in self.playlists {
            
            // check to see if the image has already been downloaded.
            do {
                let identifier = try SpotifyIdentifier(uri: playlist.uri)
                if let imageFolder = self.imageFolderURL(for: identifier) {
                    let imageURL = imageFolder.appendingPathComponent(
                        identifier.id, isDirectory: false
                    )
                    if FileManager.default.fileExists(atPath: imageURL.path) {
                        // don't download the image again if it has already
                        // been downloaded.
                        continue
                    }
                }
                
            } catch {
                Loggers.images.error(
                    "couldn't get identifier for '\(playlist.name)': \(error)"
                )
            }

            Loggers.images.notice(
                "will retrieve image for playlist '\(playlist.name)'"
            )
            
            if let image = playlist.images.smallest {
                URLSession.shared.dataTaskPublisher(for: image.url)
                    .receive(on: RunLoop.main)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                Loggers.images.error(
                                    "couldn't retrieve playlist image: \(error)"
                                )
                            }
                        },
                        receiveValue: { imageData, urlResponse in
                            do {
                                let identifier = try SpotifyIdentifier(
                                    uri: playlist
                                )
                                self.saveImageToFile(
                                    imageData: imageData,
                                    identifier: identifier
                                )
                                
                            } catch {
                                
                                Loggers.images.error(
                                    """
                                    couldn't get identifier for \
                                    '\(playlist.name)': \(error)"
                                    """
                                )
                                
                            }
                        }
                    )
                    .store(in: &cancellables)
            }
            
        }  // for playlist in self.playlists
    }

    func image(for identifier: SpotifyIdentifier) -> Image? {
        
        guard let categoryFolder = self.imageFolderURL(for: identifier) else {
            return nil
        }
        let imageURL = categoryFolder.appendingPathComponent(
            "\(identifier.id).tiff", isDirectory: false
        )
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            return nil
        }
        do {
            let imageData = try Data(contentsOf: imageURL)
            if let nsImage = NSImage(data: imageData) {
                return Image(nsImage: nsImage)
            }
            Loggers.playerManager.error(
                "couldn't convert data to image for \(identifier.uri)"
            )
            return nil
            
        } catch {
            Loggers.playerManager.error(
                "couldn't get image for \(identifier.uri): \(error)"
            )
            return nil
        }
        
    }
    
    /// Returns the folder in which the image is stored, not the full path.
    func imageFolderURL(for identifier: SpotifyIdentifier) -> URL? {
        return self.imagesFolder?.appendingPathComponent(
            identifier.idCategory.rawValue, isDirectory: true
        )
    }
    
    func saveImageToFile(imageData: Data, identifier: SpotifyIdentifier) {
        
        guard let categoryFolder = self.imageFolderURL(for: identifier) else {
            return
        }
        
        let imageURL = categoryFolder.appendingPathComponent(
            "\(identifier.id).tiff", isDirectory: false
        )
        // imagePath = Library/Application Support/images/category/id.tiff
        
        do {
            try FileManager.default.createDirectory(
                at: categoryFolder,
                withIntermediateDirectories: true
            )
            guard let nsImage = NSImage(data: imageData) else {
                return
            }
            let resizedImage = nsImage.resized(width: 30, height: 30)
            guard let newImageData = resizedImage.tiffRepresentation else {
                return
            }
            try newImageData.write(to: imageURL)
            Loggers.images.trace("did save \(identifier.uri) to file")
            self.objectWillChange.send()

        } catch {
            Loggers.playerManager.error("couldn't save image to file: \(error)")
        }

    }
    
    /// Removes the folder containing the images.
    func removeImagesCache() {
        do {
            if let folder = self.imagesFolder {
                Loggers.playerManager.trace("will delete folder: \(folder)")
                try FileManager.default.removeItem(at: folder)
            }
            
        } catch {
            Loggers.playerManager.error(
                "couldn't remove image cache: \(error)"
            )
        }
    }
    
    /// Open the currently playing track/episode in the browser.
    func openCurrentPlaybackInSpotify() {
        
        guard let identifier = self.currentTrack?.identifier else {
            Loggers.playerManager.warning("no id for current track/episode")
            return
        }
        guard let uriURL = URL(string: identifier.uri) else {
            Loggers.playerManager.error(
                "couldn't convert '\(identifier.uri)' to URL"
            )
            return
        }
        
        self.openSpotifyDesktopApplication { _, _ in
            NSWorkspace.shared.open(uriURL)
        }

    }
    
    /// Open the current artist/show in the browser.
    func openArtistOrShowInSpotify() {
        
        self.openArtistOrShowCancellable = self.syncedCurrentlyPlayingContext
            .compactMap { context -> URL? in
                if let uri = context?.showOrArtistIdentifier?.uri {
                    return URL(string: uri)
                }
                return nil
            }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "openArtistOrShowInBrowser error: \(error)"
                        )
                    }
                },
                receiveValue: { url in
                    self.openSpotifyDesktopApplication { _, _ in
                        NSWorkspace.shared.open(url)
                    }
                }
            )
            
    }
    
    func openSpotifyDesktopApplication(
        _ completionHandler: ((NSRunningApplication?, Error?) -> Void)? = nil
    ) {
        
        let spotifyPath = URL(fileURLWithPath: "/Applications/Spotify.app")
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(
            at: spotifyPath,
            configuration: configuration,
            completionHandler: completionHandler
        )

    }


    // MARK: - Notification -
    
    func presentNotification(title: String, message: String) {
        self.notificationSubject.send(
            (title: title, message: message)
        )
    }

    // MARK: - Key Events -
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(
        _ event: NSEvent,
        requireModifierKey: Bool
    ) -> Bool {
        
        // 49 == space
        if !requireModifierKey && event.keyCode == 49 {
            self.playPause()
            return true
        }

        if event.characters(byApplyingModifiers: .command) == "q" {
            NSApplication.shared.terminate(nil)
        }

        Loggers.keyEvent.trace("PlayerManager: \(event)")

        guard let shortcut = KeyboardShortcuts.Shortcut(event: event) else {
            Loggers.keyEvent.notice("couldn't get shortcut for event")
            return false
        }
        
        guard let shortcutName = KeyboardShortcuts.getName(for: shortcut) else {
            let allNames = KeyboardShortcuts.Name.allNames.map(\.rawValue)
            Loggers.keyEvent.notice(
                "couldn't get name for shortcut \(shortcut); all names: \(allNames)"
            )
            return false
        }
        
        Loggers.keyEvent.trace("shortcutName: \(shortcutName)")
        switch shortcutName {
            case .previousTrack:
                self.previousTrackOrSeekBackwards()
            case .playPause:
                self.playPause()
            case .nextTrack:
                self.nextTrackOrSeekForwards()
            case .volumeUp:
                Loggers.keyEvent.trace("increase sound volume")
                let newSoundVolume = (self.soundVolume + 5)
                    .clamped(to: 0...100)
                self.soundVolume = newSoundVolume
                self.player.setSoundVolume?(
                    Int(newSoundVolume)
                )
            case .volumeDown:
                Loggers.keyEvent.trace("decrease sound volume")
                let newSoundVolume = (self.soundVolume - 5)
                    .clamped(to: 0...100)
                self.soundVolume = newSoundVolume
                self.player.setSoundVolume?(
                    Int(newSoundVolume)
                )
            case .showPlaylists:
                if self.isShowingPlaylistsView {
                    self.dismissPlaylistsView(animated: true)
                }
                else {
                    self.presentPlaylistsView()
                }
            case .repeatMode:
                self.cycleRepeatMode()
            case .shuffle:
                self.toggleShuffle()
            case .onlyShowMyPlaylists:
                self.onlyShowMyPlaylists.toggle()
                Loggers.keyEvent.notice(
                    "onlyShowMyPlaylists = \(self.onlyShowMyPlaylists)"
                )
            case .settings:
                AppDelegate.shared.openSettingsWindow()
            default:
                return false
        }
        return true
    }

    func presentPlaylistsView() {
        self.retrievePlaylists()
        withAnimation(PlayerView.animation) {
            self.isShowingPlaylistsView = true
        }
    }

    func dismissPlaylistsView(animated: Bool) {
        if animated {
            withAnimation(PlayerView.animation) {
                self.isShowingPlaylistsView = false
            }
            self.updateSoundVolumeAndPlayerPosition()
            self.updatePlaylistsSortedByLastModifiedDate()
            self.retrieveAvailableDevices()
            self.updatePlaylistsSortedByLastModifiedDate()
        }
        else {
            self.isShowingPlaylistsView = false
        }
    }
    
}

// MARK: - - Private Members - -

private extension PlayerManager {
    
    private func receiveCurrentlyPlayingContext(
        _ context: CurrentlyPlayingContext?
    ) {
        
        guard let context = context else {
            self.currentlyPlayingContext = nil
            return
        }
        
        self.currentlyPlayingContext = context
        if let repeatMode = self.currentlyPlayingContext?.repeatState {
            self.repeatMode = repeatMode
            Loggers.playerState.trace(
                "self.repeatMode = \(self.repeatMode)"
            )
        }
        Loggers.syncContext.trace("self.currentlyPlayingContext = context")
        let name = self.currentlyPlayingContext?.item?.name ?? "nil"
        Loggers.syncContext.trace("context name: \(name)")
        
        self.isUpdatingCurrentlyPlayingContext = false
        self.didUpdateCurrentlyPlayingContext.send()
        Loggers.syncContext.trace(
            "isUpdatingCurrentlyPlayingContext = false\n"
        )
        
//        let itemName = self.currentlyPlayingContext?.item?.name ?? "nil"
//        Loggers.playerManager.trace("currentlyPlayingContext name: \(itemName)")
//        if let artist = self.currentArtist {
//            Loggers.playerManager.trace("current artist: \(artist.name)")
//        }
//        else if let show = self.currentShow {
//            Loggers.playerManager.trace("current show: \(show.name)")
//        }
//        else {
//            Loggers.playerManager.warning("no current show or artist")
//        }

        let allowedActionsString = context.allowedActions.map(\.rawValue)
        Loggers.playerState.notice(
            "allowed actions: \(allowedActionsString)"
        )
        
        
    }
    
    private func areInDecreasingOrderByDateThenIncreasingOrderByIndex(
        lhs: (index: Int, date: Date?),
        rhs: (index: Int, date: Date?)
    ) -> Bool {
        switch (lhs.date, rhs.date) {
            case (.some(let lhsDate), .some(let rhsDate)):
                if lhsDate == rhsDate {
                    return lhs.index < rhs.index
                }
                return lhsDate > rhsDate
            case (.some(_), nil):
                return true
            case (nil, .some(_)):
                return false
            default:
                return lhs.index < rhs.index
        }
    }

}