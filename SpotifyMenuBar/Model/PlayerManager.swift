import Foundation
import SwiftUI
import Combine
import ScriptingBridge
import Logging
import SpotifyWebAPI

class PlayerManager: ObservableObject {

    let spotify: Spotify
    
    // MARK: Player State
    
    /// Retrieved from the Spotify desktop application using AppleScript.
    @Published var currentTrack: SpotifyTrack? = nil
    
    var albumArtistTitle: String {
        let albumName = self.currentTrack?.album
        if let artistName = self.currentTrack?.artist {
            if let albumName = albumName {
                return "\(artistName) - \(albumName)"
            }
            return artistName
        }
        if let albumName = albumName {
            return albumName
        }
        return ""
    }
    
    @Published var shuffleIsOn = false
    @Published var repeatMode = RepeatMode.off
    @Published var playerPosition: CGFloat = 0
    @Published var soundVolume: CGFloat = 100
    
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
    
    /// Devices with `nil` for `id` and/or are restricted are filtered out.
    @Published var availableDevices: [Device] = []
    
    // MARK: Playlists

    @Published var playlists: [Playlist<PlaylistsItemsReference>] = []
    
    /// The most recently played playlists will appear first.
    @Published var playlistsSortedByLastPlayedDate:
            [Playlist<PlaylistsItemsReference>] = []
    
    /// The playlists that items were most recently added to will appear first.
    @Published var playlistsSortedByLastAddedDate:
            [Playlist<PlaylistsItemsReference>] = []
    
    /// Sorted based on the last time they were played or an item was added to
    /// them, whichever was later.
    @Published var playlistsSortedByLastedModifiedDate:
            [Playlist<PlaylistsItemsReference>] = []
    
    /// The playlists that are **owned** by the current user. These are the
    /// playlists that tracks and episodes can be added to.
    @Published var currentUserPlaylists: [Playlist<PlaylistsItemsReference>] = []
    
    var allowedActions: Set<PlaybackActions> {
        return self.currentlyPlayingContext?.allowedActions
            ?? PlaybackActions.allCases
    }
    
    @Published var currentUser: SpotifyUser? = nil
    private var currentUserPublisher: AnyPublisher<SpotifyUser, Never>? = nil
    var synchedCurrentUser: Future<SpotifyUser, Never> {
        Future { promise in
            if let currentUser = self.currentUser {
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

    
    private let playlistsLastPlayedDatesKey = "playlistsLastPlayedDate"
    private let playlistsLastAddedDatesKey = "playlistsLastAddedDate"
    
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
    
    let keyEventSubject = PassthroughSubject<NSEvent, Never>()
    
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
    
    // MARK: Cancellables
    private var cancellables: Set<AnyCancellable> = []
    private var retrieveAvailableDevicesCancellable: AnyCancellable? = nil
    private var loadArtworkImageCancellanble: AnyCancellable? = nil
    private var retrieveCurrentlyPlayingContextCancellable: AnyCancellable? = nil
    private var retrievePlaylistsCancellable: AnyCancellable? = nil
    private var retrieveCurrentUserCancellable: AnyCancellable? = nil
    private var retrieveCurrentUserPlaylistsCancellable: AnyCancellable? = nil
    private var didUpdateCurrentlyPlayingContextCancellable: AnyCancellable? = nil
    private var openArtistOrShowCancellable: AnyCancellable? = nil
    
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
        }
        .store(in: &cancellables)
        
        self.popoverDidClose.sink {
            Loggers.playerManager.trace("popoverDidDismiss")
            if self.spotify.isAuthorized {
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
                self.currentUser = nil
                self.currentUserPublisher = nil
                self.playlistsLastPlayedDates = [:]
                self.playlistsLastAddedDates = [:]
            }
            .store(in: &cancellables)
        
        if self.spotify.isAuthorized {
            self.updatePlayerState()
        }
        
//        self.spotify.api.authorizationManager.deauthorize()

    }
    
    // MARK: Playback State
    
    func updatePlayerState() {
        Loggers.playerManager.trace("will update player state")
        self.retrieveCurrentlyPlayingContext()
        self.retrieveAvailableDevices()
        self.currentTrack = self.player.currentTrack
        self.shuffleIsOn = player.shuffling ?? false
        Loggers.shuffle.trace("self.shuffleIsOn = \(self.shuffleIsOn)")
        
        let newSoundVolume = CGFloat(self.player.soundVolume ?? 100)
        if abs(newSoundVolume - self.soundVolume) >= 2 {
            self.soundVolume = newSoundVolume
//            Loggers.playerManager.trace(
//                "sound volume: \(soundVolume) to \(newSoundVolume)"
//            )
        }
        if let playerPosition = self.player.playerPosition {
//            Loggers.playerManager.trace(
//                "new player position: \(playerPosition)"
//            )
            self.playerPosition = CGFloat(playerPosition)
        }
//        Loggers.playerManager.trace(
//            "player state updated to '\(self.currentTrack?.name ?? "nil")'"
//        )
        if self.currentTrack?.artworkUrl != self.previousArtworkURL {
//            Loggers.playerManager.trace(
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
            Loggers.playerManager.warning(
                "no artwork URL or couldn't convert from String"
            )
            self.artworkImage = Image(.spotifyAlbumPlaceholder)
            return
        }
//        Loggers.playerManager.trace("loading artwork image from '\(url)'")
        self.loadArtworkImageCancellanble = URLSession.shared
            .dataTaskPublisher(for: url)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "couldn't load artwork image: \(error)"
                        )
                        // MARK: Receive Image
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                },
                receiveValue: { data, response in
                    if let nsImage = NSImage(data: data) {
                        
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
        self.retrieveAvailableDevicesCancellable = self.spotify.api
            .availableDevices()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "couldn't retreive available devices: \(error)"
                        )
                    }
                },
                receiveValue: { devices in
                    self.availableDevices = devices
                        .filter { $0.id != nil && !$0.isRestricted }
//                    Loggers.playerManager.trace(
//                        "available devices: \(self.availableDevices)"
//                    )
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
    
    // MARK: Playlists
    
    func playPlaylist(
        _ playlist: Playlist<PlaylistsItemsReference>
    ) -> AnyPublisher<Void, Error> {
        
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist),
            offset: nil
        )
        
        self.playlistsLastPlayedDates[playlist.uri] = Date()
        
        return self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .eraseToAnyPublisher()
    }
    
    /// Retreives the user's playlists.
    func retrievePlaylists() {
        
        Loggers.playerManager.trace("retrievePlaylists")
        
        let retrievePlaylistsPublisher = self.spotify.api
            .currentUserPlaylists(limit: 50)
            .extendPages(self.spotify.api)
//            .handleEvents(receiveOutput: { page in
//                Loggers.playerManager.trace(
//                    "received playlist page at offset \(page.offset)"
//                )
//            })
            .collect()
            .map { $0.flatMap(\.items) }
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .catch { error -> Empty<[Playlist<PlaylistsItemsReference>], Never> in
                Loggers.playerManager.error(
                    "couldn't retrieve playlists: \(error)"
                )
                return Empty()
            }
        
        self.retrievePlaylistsCancellable = Publishers.Zip(
            synchedCurrentUser, retrievePlaylistsPublisher
        )
        .sink { currentUser, playlists in
            self.playlists = playlists
            self.currentUserPlaylists = self.playlists.filter { playlist in
                playlist.owner?.uri == currentUser.uri
            }
            self.retrievePlaylistImages()
            self.updatePlaylistsSortedByLastPlayedDate()
            self.updatePlaylistsSortedByLastAddedDate()
            self.updatePlaylistsSortedByLastModifiedDate()
        }
           
    }
    
    /// Re-sorts the playlists by last played date.
    func updatePlaylistsSortedByLastPlayedDate() {
        Loggers.playerManager.notice(
            "updatePlaylistsSortedByLastPlayedDate"
        )
        DispatchQueue.global().async {
            let sortedPlaylists = self.playlists.enumerated().sorted {
                lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsDate = self.playlistsLastPlayedDates[lhs.1.uri]
                let rhsDate = self.playlistsLastPlayedDates[rhs.1.uri]
                return self.areInDecreasingOrderByDateOrIncreasingOrderByIndex(
                    lhs: (index: lhs.offset, date: lhsDate),
                    rhs: (index: rhs.offset, date: rhsDate)
                )
            }
            .map(\.1)
            
            DispatchQueue.main.async {
                self.playlistsSortedByLastPlayedDate = sortedPlaylists
            }
        }
    }

    /// Re-sorts the playlists by the last date items were added to them.
    func updatePlaylistsSortedByLastAddedDate() {
        Loggers.playerManager.notice("updatePlaylistsSortedByLastAddedDate")
        DispatchQueue.global().async {
            let sortedPlaylists = self.currentUserPlaylists.enumerated().sorted {
                lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsDate = self.playlistsLastAddedDates[lhs.1.uri]
                let rhsDate = self.playlistsLastAddedDates[rhs.1.uri]
                return self.areInDecreasingOrderByDateOrIncreasingOrderByIndex(
                    lhs: (index: lhs.offset, date: lhsDate),
                    rhs: (index: rhs.offset, date: rhsDate)
                )
            }
            .map(\.1)
            
            DispatchQueue.main.async {
                self.playlistsSortedByLastAddedDate = sortedPlaylists
            }
        }
    }
    
    /// Re-sorts the playlists by the last date they were played or items
    /// were added to them, whichever was more recent.
    func updatePlaylistsSortedByLastModifiedDate() {
        Loggers.playerManager.notice(
            "updatePlaylistsSOrtedByLastPlayedOrLastAddedDate"
        )
        DispatchQueue.global().async {
            let sortedPlaylists = self.playlists.enumerated().sorted {
                lhs, rhs in
                
                // return true if lhs should be ordered before rhs

                let lhsLastPlayedDate = self.playlistsLastPlayedDates[lhs.1.uri]
                let lhsLastAddedDate = self.playlistsLastAddedDates[lhs.1.uri]
                let lhsLastModifiedDate = maxNilSmallest(
                    lhsLastPlayedDate, lhsLastAddedDate
                )
                
                let rhsLastPlayedDate = self.playlistsLastPlayedDates[rhs.1.uri]
                let rhsLastAddedDate = self.playlistsLastAddedDates[rhs.1.uri]
                let rhsLastModifiedDate = maxNilSmallest(
                    rhsLastPlayedDate, rhsLastAddedDate
                )
                
                return self.areInDecreasingOrderByDateOrIncreasingOrderByIndex(
                    lhs: (index: lhs.offset, date: lhsLastModifiedDate),
                    rhs: (index: rhs.offset, date: rhsLastModifiedDate)
                )
                
            }
            .map(\.1)
            
            DispatchQueue.main.async {
                self.playlistsSortedByLastedModifiedDate = sortedPlaylists
            }
        }
    }
    
    // MARK: Images
    
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
            
            self.spotify.api.playlistImage(playlist)
                .flatMap { images -> AnyPublisher<Data, Error> in
                    guard let image = images.largest else {
                        Loggers.images.warning(
                            "images array was empty for '\(playlist.name)'"
                        )
                        return Empty().eraseToAnyPublisher()
                    }
                    guard let url = URL(string: image.url) else {
                        Loggers.images.error(
                            "couldn't conver to URL: '\(image.url)'"
                        )
                        return Empty().eraseToAnyPublisher()
                    }
                    return URLSession.shared.dataTaskPublisher(for: url)
                        .map { data, response in data }
                        .mapError { $0 as Error }
                        .eraseToAnyPublisher()
                }
                .receive(on: RunLoop.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            Loggers.images.error(
                                "couldn't retrieve playlist image: \(error)"
                            )
                        }
                    },
                    receiveValue: { imageData in
                        do {
                            self.saveImageToFile(
                                imageData: imageData,
                                identifier: try SpotifyIdentifier(uri: playlist)
                            )
                            self.objectWillChange.send()
                            
                        } catch {
                            Loggers.images.error(
                                "couldn't convert to identifier: \(error)"
                            )
                        }
                    }
                )
                .store(in: &cancellables)
        }
    }

    func image(for identifier: SpotifyIdentifier) -> Image? {
        
        guard let categoryFolder = self.imageFolderURL(for: identifier) else {
            return nil
        }
        let imageURL = categoryFolder.appendingPathComponent(
            identifier.id, isDirectory: false
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
        return imagesFolder?.appendingPathComponent(
            identifier.idCategory.rawValue, isDirectory: true
        )
    }
    
    func saveImageToFile(imageData: Data, identifier: SpotifyIdentifier) {
        
        guard let categoryFolder = self.imageFolderURL(for: identifier) else {
            return
        }
        
        let imageURL = categoryFolder.appendingPathComponent(
            identifier.id, isDirectory: false
        )
        // imagePath = Library/Application Support/images/category/id
        
        do {
            try FileManager.default.createDirectory(
                at: categoryFolder,
                withIntermediateDirectories: true
            )
            try imageData.write(to: imageURL)

        } catch {
            Loggers.playerManager.error("couldn't save image to file: \(error)")
        }

    }
    
    /// Open the currently playing track/episode in the browser.
    func openCurrentPlaybackInBrowser() {
        
        guard let identifier = self.currentTrack?.identifier else {
            print("no id for current track/episode")
            return
        }
        if let url = identifier.url {
            NSWorkspace.shared.open(url)
        }

    }
    
    /// Open the current artist/show in the browser.
    func openArtistOrShowInBrowser() {
        
        self.openArtistOrShowCancellable = self.syncedCurrentlyPlayingContext
            .compactMap { $0?.showOrArtistIdentifier?.url }
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("openArtistOrShowInBrowser error: \(error)")
                    }
                },
                receiveValue: { url in
                    NSWorkspace.shared.open(url)
                }
            )
            
    }

}

// MARK: Private Members

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
            Loggers.playerManager.trace(
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
//        print("\n\n")
        
//        let allowedActionsStrings = context.allowedActions.map(\.rawValue)
//        Loggers.playerManager.trace(
//            "allowed actions: \(allowedActionsStrings)"
//        )
        
        
    }
    
    private func retrieveCurrentUser() -> AnyPublisher<SpotifyUser, Never> {
        
        if let currentUserPublisher = self.currentUserPublisher {
            Loggers.playerManager.notice("using previous current user publisher")
            return currentUserPublisher
        }
        
        let currentUserPublisher = self.spotify.api.currentUserProfile()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .catch { error -> Empty<SpotifyUser, Never> in
                Loggers.playerManager.error(
                    "couldn't retrieve current user: \(error)"
                )
                return Empty()
            }
            .handleEvents(
                receiveOutput: { currentUser in
                    Loggers.playerManager.notice("received current user")
                    self.currentUser = currentUser
                },
                receiveCompletion: { _ in
                    self.currentUserPublisher = nil
                }
            )
            .share()
            .eraseToAnyPublisher()
        
        return currentUserPublisher
    }
    
    private func areInDecreasingOrderByDateOrIncreasingOrderByIndex(
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
