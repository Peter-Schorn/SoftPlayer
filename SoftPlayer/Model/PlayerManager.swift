import Foundation
import SwiftUI
import Combine
import ScriptingBridge
import Logging
import SpotifyWebAPI
import KeyboardShortcuts
import os

class PlayerManager: ObservableObject {
    
    static let osLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier!,
        category: .pointsOfInterest
    )
    
    let spotify: Spotify
    
    let undoManager = UndoManager()
    
    @AppStorage("libraryPage") var libraryPage = LibraryPage.playlists
    
    @AppStorage("onlyShowMyPlaylists") var onlyShowMyPlaylists = false
    
    @AppStorage("appearance") var appearance = AppAppearance.system
    
    var colorSchemeObservation: NSKeyValueObservation? = nil
    
    var colorScheme: ColorScheme {
        if let colorScheme = self.appearance.colorScheme {
            return colorScheme
        }
        return ColorScheme(
            nsAppearance: NSApplication.shared.effectiveAppearance
        ) ?? .light
    }
    
    @Published var isShowingLibraryView = false
    
    @Published var isDraggingPlaybackPositionView = false
    @Published var isDraggingSoundVolumeSlider = false
    
    /// Only scroll to the playlists search bar once after presenting the
    /// library view.
    @Published var didScrollToPlaylistsSearchBar = false
    
    /// Only scroll to the albums search bar once after presenting the
    /// library view.
    @Published var didScrollToAlbumsSearchBar = false
    
    // MARK: Touch Bar
    
    @Published var touchbarPlaylistsOffset = 0
    
    // MARK: First Responder
    
    @Published var playerViewIsFirstResponder: Bool? = nil
    @Published var playlistsScrollViewIsFirstResponder = false
    @Published var savedAlbumsGridViewIsFirstResponder = false
    @Published var queueViewIsFirstResponder: Bool? = false
    
    // MARK: - Images -
    
    var images: [SpotifyIdentifier: Image] = [:]
    
    var queueItemImages: [SpotifyIdentifier: QueueImage] = [:]
    
    // MARK: - Player State -
    
    /// The currently playing track or episode.
    ///
    /// Retrieved from the Spotify desktop application using AppleScript.
    var currentTrack: SpotifyTrack? = nil
    
    var queue: [PlaylistItem] = []
    
    /// The currently playing track or episode identifier.
    var currentItemIdentifier: SpotifyIdentifier? = nil
    
    var albumArtistTitle = ""
    
    /// The URL to the context of the current playback.
    var contextURL: URL? {
        self.storedSyncedCurrentlyPlayingContext?.context
            .flatMap { try? SpotifyIdentifier(uri: $0.uri).url }
    }
    
    /// The name of the show or artist of the current playback.
    var showOrArtistName: String? {
        guard let context = self.storedSyncedCurrentlyPlayingContext else {
            return nil
        }
        if let artist = context.artist {
            return artist.name
        }
        if let show = context.show {
            return show.name
        }
        return nil
        
    }
    
    /// The URL to the show or artist of the current playback
    var showOrArtistURL: URL? {
        self.storedSyncedCurrentlyPlayingContext?.showOrArtistIdentifier?.url
    }

    /// Set only if the playback is occurring in the context of a playlist.
    //    @Published var currentlyPlayingPlaylistName: String? = nil
    @Published var shuffleIsOn = false
    @Published var repeatMode = RepeatMode.off
    @Published var playerPosition: CGFloat = 0 {
        didSet {
            os_signpost(
                .event,
                log: Self.osLog,
                name: "did set playerPosition"
            )
            self.updateFormattedPlaybackPosition()
        }
    }
    
    @Published var soundVolume: CGFloat = 100
    
    /// Whether or not the current track is in the current user's saved tracks.
    @Published var currentTrackIsSaved = false
    
    // MARK: Player Position
    
    static let noPlaybackPositionPlaceholder = "- : -"
    
    var formattedPlaybackPosition = PlayerManager.noPlaybackPositionPlaceholder
    
    var formattedDuration = PlayerManager.noPlaybackPositionPlaceholder
    
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
    
    var storedSyncedCurrentlyPlayingContext: CurrentlyPlayingContext? = nil
    
    /// The image for the album/show of the currently playing
    /// track/episode.
    @Published var artworkImage = Image(.spotifyAlbumPlaceholder)
    
    @Published var isPlaying = false
    
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

    // MARK: - Albums -
    
    /// Each album is guaranteed to have a non-`nil` id.
    @Published var savedAlbums: [Album] = []

    @Published var isLoadingSavedAlbums = false

    private let albumsLastModifiedDatesKey = "albumsLastModifiedDates"
    
    var albumsLastModifiedDates: [String: Date]
    
    /// The dates that albums were last played. Dictionary key: album URI.
    var committedAlbumsLastModifiedDates: [String: Date] {
        get {
            return UserDefaults.standard.dictionary(
                forKey: self.albumsLastModifiedDatesKey
            ) as? [String: Date] ?? [:]
        }
        set {
            UserDefaults.standard.setValue(
                newValue,
                forKey: self.albumsLastModifiedDatesKey
            )
        }
    }
    
    /// Whether or not the saved albums have been retrieved at least once since
    /// launch or logging in to a new account.
    var didRetrieveAlbums = false

    // MARK: - Playlists -

    /// Sorted based on the last time they were played or an item was added to
    /// them, whichever was later.
    @Published var playlists: [Playlist<PlaylistItemsReference>] = []
    
    @Published var isLoadingPlaylists = false
    
    private let playlistsLastModifiedDatesKey = "playlistsLastModifiedDates"
    
    var playlistsLastModifiedDates: [String: Date]

    /// The dates that playlists were last played or items were
    /// added to them. Dictionary key: playlist URI.
    var committedPlaylistsLastModifiedDates: [String: Date] {
        get {
            return UserDefaults.standard.dictionary(
                forKey: self.playlistsLastModifiedDatesKey
            ) as? [String: Date] ?? [:]
        }
        set {
            UserDefaults.standard.setValue(
                newValue,
                forKey: self.playlistsLastModifiedDatesKey
            )
        }
    }

    /// Whether or not the playlists have been retrieved at least once since
    /// launch or logging in to a new account.
    var didRetrievePlaylists = false

    // MARK: - Queue -

    /// The last time some queue item images have been deleted because there
    /// were more than 100.
    var lastTimeDeletedExtraQueueImages: Date? = nil

    /// The last time unused images have been deleted.
    var lastTimeDeletedUnusedImages: Date? = nil
    
    // MARK: Library Page Transition
    @Published var libraryPageTransition = AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing)
    )

    // MARK: - Notification -
    
    let notificationSubject = PassthroughSubject<AlertItem, Never>()
    
    // MARK: - Publishers -
    
    let artworkURLDidChange = PassthroughSubject<Void, Never>()
    
    /// Emits when the popover is about to be shown.
    let popoverWillShow = PassthroughSubject<Void, Never>()
    
    /// Emits after the popover dismisses.
    let popoverDidClose = PassthroughSubject<Void, Never>()

    /// A publisher that emits when the Spotify player state changes.
    let playerStateDidChange = DistributedNotificationCenter
        .default().publisher(for: .spotifyPlayerStateDidChange)

    let spotifyApplication = CustomSpotifyApplication()
    
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
    private var openAlbumCancellable: AnyCancellable? = nil
    private var cycleRepeatModeCancellable: AnyCancellable? = nil
    private var updatePlayerStateCancellable: AnyCancellable? = nil
    private var retrieveCurrentlyPlayingPlaylistCancellable: AnyCancellable? = nil
    private var currentUserSavedTracksContainsCancellable: AnyCancellable? = nil
    var playerStateDidChangeCancellable: AnyCancellable? = nil
    private var retrieveSavedAlbumsCancellable: AnyCancellable? = nil
    private var playAlbumCancellable: AnyCancellable? = nil
    private var retrieveQueueCancellable: AnyCancellable? = nil
    
    init(spotify: Spotify) {
        
        self.spotify = spotify
        
        self.albumsLastModifiedDates = UserDefaults.standard.dictionary(
            forKey: self.albumsLastModifiedDatesKey
        ) as? [String: Date] ?? [:]
        
        self.playlistsLastModifiedDates = UserDefaults.standard.dictionary(
            forKey: self.playlistsLastModifiedDatesKey
        ) as? [String: Date] ?? [:]
        
        self.checkIfNotAuthorizedForNewScopes()
        self.checkIfSpotifyIsInstalled()
        self.observeColorScheme()

        self.playerStateDidChangeCancellable = self.playerStateDidChange
            .receive(on: RunLoop.main)
            .sink(receiveValue: self.receivePlayerStateDidChange(notification:))
        
        self.artworkURLDidChange
            .sink(receiveValue: self.loadArtworkImage)
            .store(in: &self.cancellables)
        
        self.popoverWillShow.sink {
            
            if self.spotify.isAuthorized {
                self.updatePlayerState()
            }
            self.updatePlayerStateCancellable = Timer.publish(
                every: 2, on: .main, in: .common
            )
            .autoconnect()
            .sink { _ in
                
                Loggers.soundVolumeAndPlayerPosition.trace("timer fired")

                guard self.spotify.isAuthorized else {
                    return
                }

                // even though the like track button is not displayed when
                // the library view is presented, users can still use a keyboard
                // shortcut to like the track
                self.checkIfCurrentTrackIsSaved()

                if self.isShowingLibraryView {
                    self.retrieveCurrentlyPlayingContext(fromTimer: true)
                    self.retrieveQueue()
                }
                else {
                    self.updateSoundVolumeAndPlayerPosition(fromTimer: true)
                    self.retrieveAvailableDevices()
                }
            }
            
        }
        .store(in: &self.cancellables)
        
        self.popoverDidClose.sink {
            Loggers.playerManager.trace("popoverDidDismiss")
            self.updatePlayerStateCancellable = nil
            self.commitModifiedDates()
            self.sortPlaylistsByLastModifiedDate(&self.playlists)
            self.sortAlbumsByLastModifiedDate(&self.savedAlbums)
        }
        .store(in: &self.cancellables)
        
        self.spotify.$isAuthorized.sink { isAuthorized in
            Loggers.playerManager.notice(
                "spotify.$isAuthorized.sink: \(isAuthorized)"
            )
            if isAuthorized {
                self.retrieveCurrentUser()
                self.retrievePlaylists()
                self.retrieveSavedAlbums()
                self.retrieveQueue()
                self.updatePlayerState()
            }
        }
        .store(in: &self.cancellables)

        self.spotify.api.authorizationManager.didDeauthorize
            .receive(on: RunLoop.main)
            .sink {
                self.currentlyPlayingContext = nil
                self.availableDevices = []
                self.currentUser = nil
                self.playlistsLastModifiedDates = [:]
                self.albumsLastModifiedDates = [:]
                self.committedAlbumsLastModifiedDates = [:]
                self.committedPlaylistsLastModifiedDates = [:]
                self.playlists = []
                self.didRetrievePlaylists = false
                self.savedAlbums = []
                self.didRetrieveAlbums = false
                self.queue = []
                self.removeImagesCache()
            }
            .store(in: &self.cancellables)

        // ensure the UI is updated after a keyboard shortcut changes
        NotificationCenter.default.publisher(for: .shortcutByNameDidChange)
            .sink { _ in
                self.objectWillChange.send()
            }
            .store(in: &self.cancellables)

//        self.debug()

    }
    
    /// Newer versions of this app have added new authorization scopes. Check
    /// if the user is only authorized for the scopes from previous versions.
    func checkIfNotAuthorizedForNewScopes() {
        
        if !self.spotify.api.authorizationManager.isAuthorized(
            for: self.spotify.scopes
        ) {
            self.spotify.api.authorizationManager.deauthorize()
        }

    }

    func observeColorScheme() {
        
        self.colorSchemeObservation = NSApplication.shared.observe(
            \.effectiveAppearance, options: .new
        ) { _, change in
//            let appearance = change.newValue?.name.rawValue
//            print(
//                """
//                NSApplication.effectiveAppearancec changed to \
//                \(appearance.map(String.init(describing:)) ?? "nil")
//                """
//            )
            self.objectWillChange.send()
        }

    }
    
    func checkIfSpotifyIsInstalled() {
        let spotifyBundleIdentifier = "com.spotify.client"
        let spotifyURL = NSWorkspace.shared
            .urlForApplication(withBundleIdentifier: spotifyBundleIdentifier)
        
        if spotifyURL == nil {
            self.showSpotifyNotInstalledAlert()
        }

    }

    func showSpotifyNotInstalledAlert() {
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(
            "Could not Connect to the Spotify Application",
            comment: ""
        )
        alert.informativeText = NSLocalizedString(
            """
            The Spotify Desktop Application is not installed or could not be \
            found. Therefore, most of the functions of this app will not work. \
            If the Spotify Application is installed, try moving it to the \
            applications folder; then, restart this app.
            """,
            comment: ""
        )
        
        alert.runModal()

    }

    // MARK: - Playback State -
    
    func updateFormattedPlaybackPosition() {
        
        // var formattedPlaybackPosition: String {
            if self.spotifyApplication?.playerPosition == nil {
                self.formattedPlaybackPosition =
                        Self.noPlaybackPositionPlaceholder
            }
            self.formattedPlaybackPosition = self.formattedTimestamp(
                self.playerPosition
            )
        // }
        
        // var formattedDuration: String {
            if self.currentTrack?.duration == nil {
                self.formattedDuration = Self.noPlaybackPositionPlaceholder
            }
            let durationSeconds = CGFloat(
                (self.currentTrack?.duration ?? 1) / 1000
            )
            self.formattedDuration = self.formattedTimestamp(durationSeconds)
        // }
        
        self.objectWillChange.send()
        
    }

    /// Returns the formatted timestamp for the duration or player position.
    private func formattedTimestamp(_ number: CGFloat) -> String {
        let formatter: DateComponentsFormatter = number >= 3600 ?
            .playbackTimeWithHours : .playbackTime
        return formatter.string(from: Double(number))
            ?? Self.noPlaybackPositionPlaceholder
    }
    
    func setAlbumArtistTitle() {
        let albumName = self.currentTrack?.album
        if let artistName = self.currentTrack?.artist, !artistName.isEmpty {
            if let albumName = albumName, !albumName.isEmpty {
                self.albumArtistTitle = "\(artistName) - \(albumName)"
            }
            else {
                self.albumArtistTitle = artistName
            }
        }
        else if let albumName = albumName, !albumName.isEmpty {
            self.albumArtistTitle = albumName
        }
        else {
            self.albumArtistTitle = ""
        }
    }
    
    func receivePlayerStateDidChange(notification: Notification) {
        
        Loggers.playerManager.trace(
            "received player state did change notification"
        )

        if let playerState = PlayerStateNotification(
            userInfo: notification.userInfo
        ) {
            
            Loggers.playerManager.trace(
                """
                playerStateDidChange: \
                \(playerState.state?.rawValue ?? "nil")
                """
            )
            if playerState.state == .stopped {
                return
            }
        }
        else {
            Loggers.playerManager.error(
                """
                could not create PlayerStateNotification from \
                notification.userInfo:
                \(notification.userInfo as Any)
                """
            )
        }

        if self.spotify.isAuthorized {
            self.updatePlayerState()
        }
        
    }

    func updatePlayerState() {
        
        Loggers.playerState.trace("will update player state")
        
        self.retrieveAvailableDevices()
        self.checkIfCurrentTrackIsSaved()
        self.retrieveQueue()

        if self.isTransferringPlayback {
            Loggers.artwork.notice(
                "not updating player state because isTransferringPlayback"
            )
            return
        }
        
        self.currentTrack = self.spotifyApplication?.currentTrack
        let newIdentifier = self.currentTrack?.identifier
        
        if let newIdentifier = newIdentifier,
                newIdentifier != self.currentItemIdentifier {
            
            self.currentTrackIsSaved = false
        }

        self.currentItemIdentifier = newIdentifier

        self.updateSoundVolumeAndPlayerPosition()
        self.retrieveCurrentlyPlayingContext()
        Loggers.playerState.trace(
            """
            player state updated from '\(self.currentTrack?.name ?? "nil")' \
            to '\(self.spotifyApplication?.currentTrack?.name ?? "nil")'
            """
        )

        self.updateFormattedPlaybackPosition()
        self.setAlbumArtistTitle()
        self.shuffleIsOn = spotifyApplication?.shuffling ?? false
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
        self.previousArtworkURL = self.spotifyApplication?.currentTrack?.artworkUrl
        
        self.isPlaying = self.spotifyApplication?.playerState == .playing

        self.objectWillChange.send()
    }
    
    func updateSoundVolumeAndPlayerPosition(
        fromTimer: Bool = false
    ) {
        Loggers.soundVolumeAndPlayerPosition.trace("")
        
        self.updateSoundVolume(
            recursionDepth: 0
        )
        self.updatePlayerPosition(
            fromTimer: fromTimer
        )

    }
    
    func updateSoundVolume(
        recursionDepth: Int = 0
    ) {
        
        Loggers.soundVolumeAndPlayerPosition.trace("")
        
        guard let intSoundVolume = self.spotifyApplication?.soundVolume else {
            Loggers.soundVolumeAndPlayerPosition.warning(
                "couldn't get sound volume"
            )
            return
        }
        
        if intSoundVolume == 0, recursionDepth <= 2 {
            Loggers.soundVolumeAndPlayerPosition.notice(
                "recursion depth: \(recursionDepth)"
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateSoundVolume(
                    recursionDepth: recursionDepth + 1
                )
            }
            return
        }
        
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
                will change sound volume from \(self.soundVolume) to \
                \(newSoundVolume)"
                """
            )
            self.soundVolume = newSoundVolume
            
        }
        
    }
    
    func updatePlayerPosition(
        fromTimer: Bool = false
    ) {
        
        guard let playerPosition = self.spotifyApplication?.playerPosition,
              !self.isDraggingPlaybackPositionView else {
            
            Loggers.soundVolumeAndPlayerPosition.debug(
                """
                couldn't get player position or is dragging slider
                """
            )
            return

        }

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
                will change player position from \(self.playerPosition) to \
                \(cgPlayerPosition)"
                """
            )
            self.playerPosition = cgPlayerPosition
        }

    }

    /// Loads the image from the artwork URL of the current track.
    func loadArtworkImage() {
        guard let url = self.currentTrack?.artworkUrl
                .flatMap(URL.init(string:)) else {
            Loggers.images.warning(
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
                        Loggers.images.error(
                            "couldn't load artwork image: \(error)"
                        )
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                },
                receiveValue: { data, response in
                    if let nsImage = NSImage(data: data) {
                        // MARK: Successfully Receive Image
                        let squareImage = nsImage.croppedToSquare() ?? nsImage
                        self.artworkImage = Image(nsImage: squareImage)
                    }
                    else {
                        Loggers.images.error(
                            "couldn't convert data to image"
                        )
                        self.artworkImage = Image(.spotifyAlbumPlaceholder)
                    }
                }
            )
    }
    
    func setPlayerPosition(to position: CGFloat) {
        self.spotifyApplication?.setPlayerPosition(Double(position))
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
    func retrieveCurrentlyPlayingContext(
        fromTimer: Bool = false,
        recursionDepth: Int = 1
    ) {
        
        if recursionDepth >= 5 {
            Loggers.syncContext.trace("recursionDepth \(recursionDepth) >= 5")
            self.currentlyPlayingContext = nil
            self.isUpdatingCurrentlyPlayingContext = false
            return
        }
        
        self.isUpdatingCurrentlyPlayingContext = true
        self.storedSyncedCurrentlyPlayingContext = nil

        Loggers.syncContext.trace(
            """
            isUpdatingCurrentlyPlayingContext = true; \
            recursionDepth: \(recursionDepth)
            """
        )
        // This delay is necessary because this request is made right
        // after playback has changed. Without this delay, the web API
        // may return information for the previous playback.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.retrieveCurrentlyPlayingContextCancellable =
                self.spotify.api.currentPlayback()
                .receive(on: RunLoop.main)
                .handleAuthenticationError(spotify: self.spotify)
                .sink(
                    receiveCompletion: { completion in
                        
                        // Don't repeatedly show an error every two seconds
                        if fromTimer {
                            return
                        }

                        if case .failure(let error) = completion {
                            Loggers.playerManager.error(
                                "couldn't get currently playing context: \(error)"
                            )
                            let alertTitle = NSLocalizedString(
                                "Couldn't Retrieve Playback State",
                                comment: ""
                            )
                            let alert = AlertItem(
                                title: alertTitle,
                                message: error.customizedLocalizedDescription
                            )
                            self.notificationSubject.send(alert)
                            self.currentlyPlayingContext = nil
                            self.isUpdatingCurrentlyPlayingContext = false
                        }
                    },
                    receiveValue: { context in
                        
                        if
                            let uriFromContext = context?.item?.uri
                                .flatMap({ try? SpotifyIdentifier(uri: $0) }),
                            let uriFromAppleScript = self.spotifyApplication?
                                    .currentTrack?.identifier,
                            uriFromContext == uriFromAppleScript
                        {
                            let contextName = context?.item?.name ?? "nil"
                            let appleScriptName = self.spotifyApplication?
                                    .currentTrack?.name ?? "nil"
                            Loggers.syncContext.trace(
                                """
                                uriFromContext == uriFromAppleScript
                                '\(contextName)' == '\(appleScriptName)'
                                """
                            )
                            self.receiveCurrentlyPlayingContext(context)

                        }
                        else if context?.itemType == .ad,
                            self.spotifyApplication?.currentTrack?.identifier?
                                    .idCategory == .ad
                        {
                            Loggers.playerState.notice(
                                "playing ad"
                            )
                            self.receiveCurrentlyPlayingContext(context)
                        }
                        else {
                            let asyncDelay = 0.4 * Double(recursionDepth)
                            Loggers.syncContext.warning(
                                """
                                uriFromContext != uriFromAppleScript \
                                or ad for only one source; \
                                asyncDelay: \(asyncDelay)
                                """
                            )
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + asyncDelay
                            ) {
                                self.retrieveCurrentlyPlayingContext(
                                    recursionDepth: recursionDepth + 1
                                )
                            }
                        }
                       
                    }
                )
        }
        
    }
    
//    func retrieveCurrentlyPlayingPlaylist() {
//
//        guard let context = self.currentlyPlayingContext?.context,
//                context.type == .playlist else {
//            self.currentlyPlayingPlaylistName = nil
//            return
//        }
//
//        let playlistURI = context.uri
//
//        self.retrieveCurrentlyPlayingPlaylistCancellable = self.spotify.api
//            .playlistName(playlistURI)
//            .receive(on: RunLoop.main)
//            .handleAuthenticationError(spotify: self.spotify)
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure(let error) = completion {
//                        self.currentlyPlayingPlaylistName = nil
//                        Loggers.playerState.error(
//                            """
//                            could not retrieve playlist name for \(playlistURI): \
//                            \(error)
//                            """
//                        )
//                    }
//                },
//                receiveValue: { playlistName in
//                    self.currentlyPlayingPlaylistName = playlistName
//                }
//            )
//
//    }

    // MARK: - Player Controls -
    
    func cycleRepeatMode() {
        self.repeatMode.cycle()
        self.cycleRepeatModeCancellable = self.spotify.api
            .setRepeatMode(to: self.repeatMode)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(receiveCompletion: { completion in
                let repeatModeString = self.repeatMode.localizedDescription
                switch completion {
                    case .failure(let error):
                        let alertTitle = String.localizedStringWithFormat(
                            NSLocalizedString(
                                "Couldn't Set the Repeat Mode to %@",
                                comment: ""
                            ),
                            repeatModeString
                        )
                        let alert = AlertItem(
                            title: alertTitle,
                            message: error.customizedLocalizedDescription
                        )
                        self.notificationSubject.send(alert)
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
        self.spotifyApplication?.setShuffling(
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
        self.spotifyApplication?.previousTrack()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updatePlayerState()
        }
    }
    
    func seekBackwards15Seconds() {
        guard let currentPosition = self.spotifyApplication?.playerPosition else {
            Loggers.soundVolumeAndPlayerPosition.error(
                "couldn't get player position"
            )
            return
        }
        let newPosition = max(0, currentPosition - 15)
        self.setPlayerPosition(to: CGFloat(newPosition))
        self.lastAdjustedPlayerPositionDate = Date()
    }
    
    func playPause() {
        self.spotifyApplication?.playpause()
    }

    func skipToNextTrack() {
        Loggers.playerState.trace("")
        self.spotifyApplication?.nextTrack()
    }
    
    func seekForwards15Seconds() {
        guard let currentPosition = self.spotifyApplication?.playerPosition else {
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
        self.lastAdjustedPlayerPositionDate = Date()
    }
    
    // MARK: - Saved Tracks -
 
    func addOrRemoveCurrentTrackFromSavedTracks() {
        if self.currentTrackIsSaved {
            self.addCurrentTrackToSavedTracks()
        }
        else {
            self.removeCurrentTrackFromSavedTracks()
        }
    }
    
    func addCurrentTrackToSavedTracks() {
        guard let trackURI = self.currentTrack?.identifier,
                trackURI.idCategory == .track else {
            return
        }
        self.addTrackToSavedTracks(trackURI)
    }
    
    func removeCurrentTrackFromSavedTracks() {
        guard let trackURI = self.currentTrack?.identifier else {
            return
        }
        self.removeTrackFromSavedTracks(trackURI)
    }

    func addTrackToSavedTracks(_ trackURI: SpotifyURIConvertible) {
        
        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.removeTrackFromSavedTracks(trackURI)
        }

        self.spotify.api.saveTracksForCurrentUser([trackURI])
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink { completion in
                Loggers.playerManager.trace(
                    "addTrackToSavedTracks completion: \(completion)"
                )
                switch completion {
                    case .finished:
                        self.checkIfCurrentTrackIsSaved()
                    case .failure(let error):
                        Loggers.playerManager.error(
                            "Couldn't save track \(trackURI.uri): \(error)"
                        )
                }
            }
            .store(in: &self.cancellables)
        
    }
    
    func removeTrackFromSavedTracks(_ trackURI: SpotifyURIConvertible) {
        
        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.addTrackToSavedTracks(trackURI)
        }

        self.spotify.api.removeSavedTracksForCurrentUser([trackURI])
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink { completion in
                Loggers.playerManager.trace(
                    "removeTrackFromSavedTracks completion: \(completion)"
                )
                switch completion {
                    case .finished:
                        self.checkIfCurrentTrackIsSaved()
                    case .failure(let error):
                        Loggers.playerManager.error(
                            "Couldn't unsave track \(trackURI.uri): \(error)"
                        )
                }
            }
            .store(in: &self.cancellables)
        
    }
    
    /// Check if the currently playing track is in the user's saved tracks.
    func checkIfCurrentTrackIsSaved() {
        
        guard let trackURI = self.currentTrack?.identifier,
                trackURI.idCategory == .track else {
            self.currentTrackIsSaved = false
            return
        }

        self.currentUserSavedTracksContainsCancellable = self.spotify.api
            .currentUserSavedTracksContains([trackURI])
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.trace(
                            """
                            error for currentUserSavedTracksContains \
                            with uri \(trackURI): \(error)
                            """
                        )
                    }
                },
                receiveValue: { results in
                    if let trackIsSaved = results.first {
                        // prevent unecessary updates
                        if self.currentTrackIsSaved != trackIsSaved {
                            self.currentTrackIsSaved = trackIsSaved
                        }
                    }
                }
            )
        
    }

//    func retrieveSavedTracks() {
//
//        self.spotify.api.currentUserSavedTracks(
//            limit: 50
//        )
//        .extendPagesConcurrently(self.spotify.api)
//        .collectAndSortByOffset()
//        .receive(on: RunLoop.main)
//        .handleAuthenticationError(spotify: self.spotify)
//        .sink(
//            receiveCompletion: { completion in
//                Loggers.playerManager.trace(
//                    "retrieveSavedTracks completion: \(completion)"
//                )
//            },
//            receiveValue: { savedTracks in
//                let tracks = savedTracks.map(\.item)
//                self.savedTracks = tracks
//            }
//        )
//        .store(in: &self.cancellables)
//
//    }

    // MARK: - Albums -
    
    func retrieveSavedAlbums() {
        
        self.isLoadingSavedAlbums = true

        self.retrieveSavedAlbumsCancellable = spotify.api
            .currentUserSavedAlbums(limit: 50)
            .extendPagesConcurrently(spotify.api)
            .collectAndSortByOffset()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingSavedAlbums = false
                    self.didRetrieveAlbums = true
                    if self.didRetrievePlaylists {
                        self.deleteUnusedImagesIfNeeded()
                    }
                    switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            let title = NSLocalizedString(
                                "Couldn't Retrieve Albums",
                                comment: ""
                            )
                            Loggers.playerManager.error("\(title): \(error)")
                            let alert = AlertItem(
                                title: title,
                                message: error.customizedLocalizedDescription
                            )
                            self.notificationSubject.send(alert)
                    }
                },
                receiveValue: { savedAlbums in
                    var savedAlbums = savedAlbums
                        .map(\.item)
                        /*
                         Remove albums that have a `nil` id so that this
                         property can be used as the id in a ForEach.
                         (The id must be unique; otherwise, the app will crash.)
                         In theory, the id should never be `nil` when the albums
                         are retrieved using the `currentUserSavedAlbums()`
                         endpoint.
                         
                         Using \.self in the ForEach is extremely expensive as
                         this involves calculating the hash of the entire
                         `Album` instance, which is very large.
                         */
                        .filter { $0.id != nil }
                    
                    self.sortAlbumsByLastModifiedDate(&savedAlbums)
                    self.savedAlbums = savedAlbums
                    self.retrieveAlbumImages()

                }
            )

    }

    func addAlbumToLibrary(_ album: Album) {
        
        guard let albumURI = album.uri else {
            NSSound.beep()
            return
        }

        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.removeAlbumFromLibrary(album)
        }

        self.spotify.api.saveAlbumsForCurrentUser(
            [albumURI]
        )
        .receive(on: RunLoop.main)
        .handleAuthenticationError(spotify: self.spotify)
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    self.retrieveSavedAlbums()
                case .failure(let error):
                    let alertTitle = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "Couldn't Save Album \"%@\"",
                            comment: "Couldn't Save Album [album name]"
                        ),
                        album.name
                    )

                    let alert = AlertItem(
                        title: alertTitle,
                        message: error.customizedLocalizedDescription
                    )
                    self.notificationSubject.send(alert)
                    Loggers.playerManager.error(
                        "\(alertTitle): \(error)"
                    )
            }
        })
        .store(in: &self.cancellables)
        
    }
    
    func removeAlbumFromLibrary(_ album: Album) {

        guard let albumURI = album.uri else {
            NSSound.beep()
            return
        }

        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.addAlbumToLibrary(album)
        }

        self.spotify.api.removeSavedAlbumsForCurrentUser(
            [albumURI]
        )
        .receive(on: RunLoop.main)
        .handleAuthenticationError(spotify: self.spotify)
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    self.retrieveSavedAlbums()
                case .failure(let error):
                    let alertTitle = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "Couldn't Remove Album \"%@\"",
                            comment: "Couldn't Remove Album [album name]"
                        ),
                        album.name
                    )

                    let alert = AlertItem(
                        title: alertTitle,
                        message: error.customizedLocalizedDescription
                    )
                    self.notificationSubject.send(alert)
                    Loggers.playerManager.error(
                        "\(alertTitle): \(error)"
                    )
            }
        })
        .store(in: &self.cancellables)
        
    }

    func playAlbum(_ album: Album) {
        
        guard let albumURI = album.uri else {
            let title = String.localizedStringWithFormat(
                NSLocalizedString(
                    "Couldn't Play \"%@\"",
                    comment: "Couldn't Play [album name]"
                ),
                album.name
            )
            Loggers.playerManager.error("\(title): no uri")
            let message = NSLocalizedString(
                "Missing data.",
                comment: ""
            )
            let alert = AlertItem(title: title, message: message)
            self.notificationSubject.send(alert)
            return
        }

        self.albumsLastModifiedDates[albumURI] = Date()

        let playbackRequest = PlaybackRequest(
            context: .contextURI(albumURI),
            offset: nil
        )
        
        self.playAlbumCancellable = self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    let title = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "Couldn't Play \"%@\"",
                            comment: "Couldn't Play [album name]"
                        ),
                        album.name
                    )
                    Loggers.playerManager.error("\(title): \(error)")
                    let message = error.customizedLocalizedDescription
                    let alert = AlertItem(title: title, message: message)
                    self.notificationSubject.send(alert)
                }
            })

    }

    // MARK: - Playlists -
    
    func playPlaylist(
        _ playlist: Playlist<PlaylistItemsReference>
    ) -> AnyPublisher<Void, AlertItem> {
        
        let playbackRequest = PlaybackRequest(
            context: .contextURI(playlist),
            offset: nil
        )
        
        self.playlistsLastModifiedDates[playlist.uri] = Date()
        
        return self.spotify.api
            .getAvailableDeviceThenPlay(playbackRequest)
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .mapError { error -> AlertItem in
                let title = String.localizedStringWithFormat(
                    NSLocalizedString(
                        "Couldn't Play \"%@\"",
                        comment: "Couldn't Play [playlist name]"
                    ),
                    playlist.name
                )
                Loggers.playerManager.error("\(title): \(error)")
                let message = error.customizedLocalizedDescription
                return AlertItem(title: title, message: message)
            }
            .eraseToAnyPublisher()
        
    }
    
    /// Retrieve the current user's playlists.
    func retrievePlaylists() {
        
        self.isLoadingPlaylists = true

        self.retrievePlaylistsCancellable = self.spotify.api
            .currentUserPlaylists(limit: 50)
            .extendPagesConcurrently(self.spotify.api)
            .collectAndSortByOffset()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingPlaylists = false
                    self.didRetrievePlaylists = true
                    if self.didRetrieveAlbums {
                        self.deleteUnusedImagesIfNeeded()
                    }
                    Loggers.playerManager.trace(
                        "retrievePlaylists completion: \(completion)"
                    )
                    guard case .failure(let error) = completion else {
                        return
                    }
                    let alertTitle = NSLocalizedString(
                        "Couldn't Retrieve Playlists",
                        comment: ""
                    )
                    Loggers.playerManager.error(
                        "\(alertTitle): \(error)"
                    )
                    let alert = AlertItem(
                        title: alertTitle,
                        message: error.customizedLocalizedDescription
                    )
                    self.notificationSubject.send(alert)
                    
                },
                receiveValue: { playlists in
                    
                    var playlists = playlists

                    if let currentUser = self.currentUser {
                        
                        let uri = "spotify:user:\(currentUser.id):collection"

                        let savedTracksPlaylist = Playlist(
                            name: "Liked Songs",
                            items: PlaylistItemsReference(href: nil, total: 0),
                            owner: currentUser,
                            isPublic: nil,
                            isCollaborative: false,
                            snapshotId: "",
                            href: .example,
                            id: "collection",
                            uri: uri,
                            images: []
                        )
                        
                        playlists.insert(savedTracksPlaylist, at: 0)

                    }

                    self.sortPlaylistsByLastModifiedDate(&playlists)
                    self.playlists = playlists
                    self.retrievePlaylistImages()
                }
            )

    }
    
    /// Adds the currently playing track/episode to a playlist.
    func addCurrentItemToPlaylist(
        playlist: Playlist<PlaylistItemsReference>
    ) {

        let itemName = self.currentTrack?.name ?? "unknown"

        guard let itemIdentifier = self.currentTrack?.identifier else {
            Loggers.playerManager.notice(
                """
                Couldn't parse SpotifyIdentifier from URI: \
                \(self.currentTrack?.id?() ?? "nil")
                """
            )
            let title: String
            if self.currentTrack?.isLocal == true {
                title = NSLocalizedString(
                    "Local tracks cannot be added to a playlist",
                    comment: ""
                )
            }
            else {
                title = NSLocalizedString(
                    "This item cannot be added to a playlist",
                    comment: ""
                )
            }
            let alert = AlertItem(title: title, message: "")
            self.notificationSubject.send(alert)
            return
        }
        
        if itemIdentifier.idCategory != .track && playlist.uri.isSavedTracksURI {
            // if the user is trying to add a non-track to the saved tracks
            // playlist
            let alertTitle = String.localizedStringWithFormat(
                NSLocalizedString(
                    "Cannot add \"%@\" to \"Liked Songs\"",
                    comment: "Cannot add [song name] to Liked Songs"
                ),
                itemName
            )
            let message = String.localizedStringWithFormat(
                "Only tracks can be added."
            )
            let alert = AlertItem(title: alertTitle, message: message)
            self.notificationSubject.send(alert)
            return
            
            
        }
        
        
        self.playlistsLastModifiedDates[playlist.uri] = Date()
        
        self.addItemToPlaylist(
            itemURI: itemIdentifier,
            itemName: itemName,
            playlist: playlist
        )

    }

    /**
     Adds a track/episode to a playlist.
     
     - Parameters:
       - itemURI: The URI of a track/episode.
       - itemName: The name of the track/episode.
       - playlist: The playlist to add the item to.
     */
    func addItemToPlaylist(
        itemURI: SpotifyURIConvertible,
        itemName: String,
        playlist: Playlist<PlaylistItemsReference>
    ) {
        
        Loggers.playerManager.notice(
            "will add '\(itemName)' to '\(playlist.name)'"
        )

        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.removeItemFromPlaylist(
                itemURI: itemURI,
                itemName: itemName,
                playlist: playlist
            )
        }
        
        let publisher: AnyPublisher<Void, Error>
        
        if playlist.uri.isSavedTracksURI {
            publisher = self.spotify.api.saveTracksForCurrentUser(
                [itemURI]
            )
        }
        else {
            publisher = self.spotify.api.addToPlaylist(
                playlist, uris: [itemURI]
            )
            .map { _ in }
            .eraseToAnyPublisher()
        }
        
        publisher
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            let alertTitle = String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "Added \"%@\" to \"%@\"",
                                    comment: "Added [song name] to [playlist name]"
                                ),
                                itemName, playlist.name
                            )
                            let alert = AlertItem(title: alertTitle, message: "")
                            self.notificationSubject.send(alert)
                        case .failure(let error):

                            let alertTitle = String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "Couldn't Add \"%@\" to \"%@\"",
                                    comment: "Couldn't Add [song name] to [playlist name]"
                                ),
                                itemName, playlist.name
                            )

                            let alert = AlertItem(
                                title: alertTitle,
                                message: error.customizedLocalizedDescription
                            )
                            self.notificationSubject.send(alert)
                            Loggers.playlistCellView.error(
                                "\(alertTitle): \(error)"
                            )
                    }
                },
                receiveValue: { }
            )
            .store(in: &self.cancellables)

    }

    /**
     Removes a track/episode from a playlist.
     
     - Parameters:
       - itemURI: The URI of a track/episode.
       - itemName: The name of the track/episode.
       - playlist: The playlist to remove the item from.
     */
    func removeItemFromPlaylist(
        itemURI: SpotifyURIConvertible,
        itemName: String,
        playlist: Playlist<PlaylistItemsReference>
    ) {
       
        Loggers.playerManager.notice(
            "will remove '\(itemName)' from '\(playlist.name)'"
        )

        self.undoManager.registerUndo(withTarget: self) { playerManager in
            playerManager.addItemToPlaylist(
                itemURI: itemURI,
                itemName: itemName,
                playlist: playlist
            )
        }
        
        let publisher: AnyPublisher<Void, Error>
        
        if playlist.uri.isSavedTracksURI {
            publisher = self.spotify.api.removeSavedTracksForCurrentUser(
                [itemURI]
            )
        }
        else {
            publisher = self.spotify.api.removeAllOccurrencesFromPlaylist(
                playlist, of: [itemURI]
            )
            .map { _ in }
            .eraseToAnyPublisher()
        }
       
        publisher
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                        case .finished:
                            let alertTitle = String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "Removed \"%@\" from \"%@\"",
                                    comment: "Removed [song name] from [playlist name]"
                                ),
                                itemName, playlist.name
                            )
                            let alert = AlertItem(title: alertTitle, message: "")
                            self.notificationSubject.send(alert)
                        case .failure(let error):
                            
                            let alertTitle = String.localizedStringWithFormat(
                                NSLocalizedString(
                                    "Couldn't Remove \"%@\" from \"%@\"",
                                    comment: "Couldn't Remove [song name] from [playlist name]"
                                ),
                                itemName, playlist.name
                            )

                            let alert = AlertItem(
                                title: alertTitle,
                                message: error.customizedLocalizedDescription
                            )
                            self.notificationSubject.send(alert)
                            Loggers.playlistCellView.error(
                                "\(alertTitle): \(error)"
                            )
                    }
                },
                receiveValue: { }
            )
            .store(in: &self.cancellables)

    }

    func followPlaylist(_ playlist: Playlist<PlaylistItemsReference>) {
        
        Loggers.playerManager.trace("will follow playlist \(playlist.name)")

        self.undoManager.registerUndo(
            withTarget: self
        ) { playerManager in
            playerManager.unfollowPlaylist(playlist)
        }

        self.spotify.api.followPlaylistForCurrentUser(
            playlist.uri
        )
        .receive(on: RunLoop.main)
        .handleAuthenticationError(spotify: self.spotify)
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    Loggers.playerManager.trace(
                        "did follow playlist \(playlist.name)"
                    )
                    self.retrievePlaylists()
                case .failure(let error):
                    let alertTitle = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "Couldn't Follow \"%@\"",
                            comment: "Couldn't Follow [playlist name]"
                        ),
                        playlist.name
                    )

                    let alert = AlertItem(
                        title: alertTitle,
                        message: error.customizedLocalizedDescription
                    )
                    self.notificationSubject.send(alert)
                    Loggers.spotify.error(
                        "\(alertTitle): \(error)"
                    )
            }
        })
        .store(in: &self.cancellables)
    }
    
    func unfollowPlaylist(_ playlist: Playlist<PlaylistItemsReference>) {
        
        Loggers.playerManager.trace("will unfollow playlist \(playlist.name)")

        self.undoManager.registerUndo(
            withTarget: self
        ) { playerManager in
            playerManager.followPlaylist(playlist)
        }

        self.spotify.api.unfollowPlaylistForCurrentUser(
            playlist.uri
        )
        .receive(on: RunLoop.main)
        .handleAuthenticationError(spotify: self.spotify)
        .sink(receiveCompletion: { completion in
            switch completion {
                case .finished:
                    Loggers.playerManager.trace(
                        "did unfollow playlist \(playlist.name)"
                    )
                    self.retrievePlaylists()
                case .failure(let error):
                    let alertTitle = String.localizedStringWithFormat(
                        NSLocalizedString(
                            "Couldn't Unfollow \"%@\"",
                            comment: "Couldn't Unfollow [playlist name]"
                        ),
                        playlist.name
                    )

                    let alert = AlertItem(
                        title: alertTitle,
                        message: error.customizedLocalizedDescription
                    )
                    self.notificationSubject.send(alert)
                    Loggers.spotify.error(
                        "\(alertTitle): \(error)"
                    )
            }
        })
        .store(in: &self.cancellables)
    }

    /// Re-sorts the playlists by the last date they were played or items
    /// were added to them, whichever was more recent.
    func sortPlaylistsByLastModifiedDate(
        _ playlists: inout [Playlist<PlaylistItemsReference>]
    ) {
        
        Loggers.playerManager.trace(
            "sortPlaylistsByLastModifiedDate"
        )
        
        let dates = self.committedPlaylistsLastModifiedDates
        let sortedPlaylists = playlists.enumerated().sorted {
            lhs, rhs in
            
            // return true if lhs should be ordered before rhs

            let lhsDate = dates[lhs.1.uri]
            let rhsDate = dates[rhs.1.uri]
            return self.areInDecreasingOrderByDateThenIncreasingOrderByIndex(
                lhs: (index: lhs.offset, date: lhsDate),
                rhs: (index: rhs.offset, date: rhsDate)
            )
        }
        .map(\.1)
            
        playlists = sortedPlaylists
    }
    
    /// Re-sorts the albums by the last date they were played.
    func sortAlbumsByLastModifiedDate(
        _ savedAlbums: inout [Album]
    ) {
        
        Loggers.playerManager.trace(
            "sortAlbumsByLastModifiedDate"
        )
        
        let dates = self.committedAlbumsLastModifiedDates
        let sortedAlbums = savedAlbums.enumerated().sorted {
            lhs, rhs in
            
            // return true if lhs should be ordered before rhs
            
            let lhsDate = lhs.1.uri.flatMap { dates[$0] }
            let rhsDate = rhs.1.uri.flatMap { dates[$0] }
            return self.areInDecreasingOrderByDateThenIncreasingOrderByIndex(
                lhs: (index: lhs.offset, date: lhsDate),
                rhs: (index: rhs.offset, date: rhsDate)
            )
        }
        .map(\.1)
        
        savedAlbums = sortedAlbums
            
    }
    
    // MARK: - Queue -
    
    func retrieveQueue(retries: Int = 2) {
        
        Loggers.queue.trace("retriving queue")

        self.retrieveQueueCancellable = self.spotify.api.queue()
            .receive(on: RunLoop.main)
            .handleAuthenticationError(spotify: self.spotify)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "couldn't retrieve queue: \(error)"
                        )
                    }
                },
                receiveValue: { queue in
                    if queue.queue.isEmpty && retries > 0 {
                        let delay = retries == 2 ? 0.5 : 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                            self.retrieveQueue(retries: retries - 1)
                        }
                    }
                    else {
                        self.queue = queue.queue
                        self.objectWillChange.send()
                        Loggers.queue.trace("updated queue")
                        self.retrieveQueueItemImages()
                    }

                }
            )

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
                        let alertTitle = NSLocalizedString(
                            "Couldn't Retrieve User Profile",
                            comment: ""
                        )
                        Loggers.playerManager.error(
                            "\(alertTitle): \(error)"
                        )
                        let alert = AlertItem(
                            title: alertTitle,
                            message: error.customizedLocalizedDescription
                        )
                        self.notificationSubject.send(alert)
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

    func retrieveAlbumImages() {
        
        var onDiskAlbumIds: Set<String> = []
        
        if let albumImagesFolder = self.imageFolderURL(for: .album) {
            do {
                for file in try FileManager.default.contentsOfDirectory(
                    at: albumImagesFolder,
                    includingPropertiesForKeys: [],
                    options: .skipsHiddenFiles
                ) {
                    let fileName = file.lastPathComponent
                    if let id = try! fileName.regexMatch(#"(.+)\.\w+"#)?
                            .groups.first??.match {
                        onDiskAlbumIds.insert(id)
                    }
                }
                
            } catch {
                Loggers.images.error(
                    "couldn't list directory \(albumImagesFolder.path)"
                )
            }
        }

        for album in self.savedAlbums {
            
            guard
                let albumURI = album.uri,
                let albumIdentifier = try? SpotifyIdentifier(uri: albumURI)
            else {
                Loggers.images.error(
                    """
                    couldn't get uri or identifier for album '\(album.name)'
                    """
                )
                continue
            }

            guard self.images[albumIdentifier] == nil else {
                // the image already exists in the cache, so we don't need
                // to retrieve it again
                continue
            }
            
            guard !onDiskAlbumIds.contains(albumIdentifier.id) else {
                // the image already exists on the file system, so we don't need
                // to retrieve it again
                continue
            }
            
            guard let spotifyImage = album.images?.smallest else {
                Loggers.images.warning(
                    "no images exist for album '\(album.name)'"
                )
                continue
            }

            Loggers.images.notice(
                "will retrieve image for album '\(album.name)'"
            )
            
            guard let albumsFolder = self.imageFolderURL(
                for: .album
            ) else {
                return
            }
            
            self.downloadImage(
                url: spotifyImage.url,
                identifier: albumIdentifier,
                folder: albumsFolder
            )

        }
        
    }
    
    func retrievePlaylistImages() {
        
        var onDiskPlaylistIds: Set<String> = []
        
        if let playlistImagesFolder = self.imageFolderURL(for: .playlist) {
            do {
                for file in try FileManager.default.contentsOfDirectory(
                    at: playlistImagesFolder,
                    includingPropertiesForKeys: [],
                    options: .skipsHiddenFiles
                ) {
                    let fileName = file.lastPathComponent
                    if let id = try! fileName.regexMatch(#"(.+)\.\w+"#)?
                            .groups.first??.match {
                        onDiskPlaylistIds.insert(id)
                    }
                }
                
            } catch {
                Loggers.images.error(
                    "couldn't list directory \(playlistImagesFolder.path)"
                )
            }
        }

        for playlist in self.playlists {
            
            let playlistIdentifier: SpotifyIdentifier
            do {
                playlistIdentifier = try SpotifyIdentifier(uri: playlist)
                
            } catch {
                Loggers.images.error(
                    """
                    couldn't get identifier for playlist '\(playlist.name)': \
                    \(error)
                    """
                )
                continue
            }
            
            guard self.images[playlistIdentifier] == nil else {
                // the image already exists in the cache, so we don't need
                // to retrieve it again
                continue
            }

            guard !onDiskPlaylistIds.contains(playlistIdentifier.id) else {
                // the image already exists on the file system, so we don't need
                // to retrieve it again
                continue
            }

            guard let spotifyImage = playlist.images.smallest else {
                Loggers.images.warning(
                    "no images exist for playlist '\(playlist.name)'"
                )
                continue
            }
            
            Loggers.images.notice(
                "will retrieve image for playlist '\(playlist.name)'"
            )
            
            guard let playlistsFolder = self.imageFolderURL(
                for: .playlist
            ) else {
                return
            }
            
            self.downloadImage(
                url: spotifyImage.url,
                identifier: playlistIdentifier,
                folder: playlistsFolder
            )

        }  // for playlist in self.playlists
            
    }

    func retrieveQueueItemImages() {

        self.deleteExtraQueueItemImagesIfNeeded()
        
        let savedAlbumURIs = Set(self.savedAlbums.compactMap(\.uri))

        for queueItem in self.queue {
            
            if case .track(let track) = queueItem,
                    let albumURI = track.album?.uri,
                    savedAlbumURIs.contains(albumURI) {
                // the image is already downloaded as part of the saved
                // album images
                continue
            }

            guard let imageIdentifier = self.queueItemImageIdentifier(
                queueItem
            ) else {
                continue
            }
            
            guard self.queueItemImages[imageIdentifier] == nil else {
                self.queueItemImages[imageIdentifier]?.lastAccessed = Date()
                continue
            }

            let imageURL: URL?

            switch queueItem {
                case .track(let track):
                    if track.album?.uri != nil,
                            !(track.album?.images?.isEmpty ?? true) {
                        imageURL = track.album?.images?.smallest?.url
                    }
                    // fall back on using the artist image if no album image
                    // exists
                    else if let artist = track.artists?.first(where: {
                        !($0.images?.isEmpty ?? true) && $0.uri != nil
                    }) {
                        imageURL = artist.images?.smallest?.url
                    }
                    else {
                        imageURL = nil
                    }
                        
                case .episode(let episode):
                    if let episodeImageURL = episode.images?.smallest?.url {
                        imageURL = episodeImageURL
                    }
                    // fall back on using the show image if no episode image
                    // exists
                    else if let showImageURL = episode.show?.images?.smallest?
                            .url {
                        imageURL = showImageURL
                    }
                    else {
                        imageURL = nil
                    }
            }

            guard let imageURL = imageURL else {
                continue
            }
            
            URLSession.shared.dataTaskPublisher(for: imageURL)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            Loggers.images.error(
                                "couldn't retrieve image: \(error)"
                            )
                        }
                    },
                    receiveValue: { imageData, urlResponse in
                        guard let nsImage = NSImage(data: imageData) else {
                            Loggers.images.error(
                                """
                                couldn't initialize NSImage from data: \
                                \(imageIdentifier.uri)
                                """
                            )
                            return
                        }
                        let imageSize: CGFloat = 40
                        guard let resizedImage = nsImage.croppedToSquare()?
                                .resized(
                                    width: imageSize, height: imageSize
                                ) else {
                            Loggers.images.error(
                                "couldn't crop image: \(imageIdentifier.uri)"
                            )
                            return
                                    
                        }
                        let image = Image(nsImage: resizedImage)
                        DispatchQueue.main.async {
                            let queueImage = QueueImage(image)
                            self.queueItemImages[imageIdentifier] = queueImage
                            self.objectWillChange.send()
                        }
                    }
                )
                .store(in: &self.cancellables)
            
            
        }

    }
    
    func queueItemImageIdentifier(_ item: PlaylistItem) -> SpotifyIdentifier? {
        switch item {
            case .track(let track):
                if let albumURI = track.album?.uri,
                   !(track.album?.images?.isEmpty ?? true),
                        let albumIdentifier = try? SpotifyIdentifier(
                            uri: albumURI
                        ) {
                    return albumIdentifier
                }
                // fall back on using the artist image if no album image
                // exists
                else if let artist = track.artists?.first(where: {
                    !($0.images?.isEmpty ?? true) && $0.uri != nil
                }), let artistURI = artist.uri,
                       let artistIdentifier = try? SpotifyIdentifier(
                        uri: artistURI
                       ) {
                    return artistIdentifier
                }
                else {
                    return nil
                }
                    
            case .episode(let episode):
                if episode.images?.smallest?.url != nil,
                        let episodeIdentifier = try? SpotifyIdentifier(uri: episode) {
                    return episodeIdentifier
                }
                // fall back on using the show image if no episode image
                // exists
                else if let show = episode.show,
                        let showIdentifier = try? SpotifyIdentifier(uri: show) {
                    return showIdentifier
                }
                else {
                    return nil
                }
        }
    }

    func queueItemImage(for item: PlaylistItem) -> Image? {

        guard let imageIdentifier = self.queueItemImageIdentifier(item) else {
            return nil
        }

        if let queueImage = self.queueItemImages[imageIdentifier] {
            return queueImage.image
        }
        
        if let image = self.image(for: imageIdentifier) {
            return image
        }

        return nil

    }

    /// Only for playlist and album images, not queue item images
    func image(for identifier: SpotifyIdentifier) -> Image? {
        
        if let image = self.images[identifier] {
            return image
        }
        
        Loggers.images.notice(
            "could not find image in cache for \(identifier.uri)"
        )
        
        guard let categoryFolder = self.imageFolderURL(
            for: identifier.idCategory
        ) else {
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
                let image = Image(nsImage: nsImage)
                self.images[identifier] = image
                return image
            }
            Loggers.images.error(
                "couldn't convert data to image for \(identifier.uri)"
            )
            return nil
            
        } catch {
            Loggers.images.error(
                "couldn't get image for \(identifier.uri): \(error)"
            )
            return nil
        }
        
    }
    
    /// Returns the folder in which the image is stored, not the full path.
    func imageFolderURL(for idCategory: IDCategory) -> URL? {
        return self.imagesFolder?.appendingPathComponent(
            idCategory.rawValue, isDirectory: true
        )
    }
    
    func downloadImage(
        url: URL,
        identifier: SpotifyIdentifier,
        folder: URL
    ) {
        URLSession.shared.dataTaskPublisher(for: url)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.images.error(
                            "couldn't retrieve image: \(error)"
                        )
                    }
                },
                receiveValue: { imageData, urlResponse in
                    self.saveImageToFile(
                        imageData: imageData,
                        identifier: identifier,
                        folder: folder
                    )
                }
            )
            .store(in: &self.cancellables)
    }

    func saveImageToFile(
        imageData: Data,
        identifier: SpotifyIdentifier,
        folder: URL
    ) {
        
        DispatchQueue.global().async {
            
            do {
                try FileManager.default.createDirectory(
                    at: folder,
                    withIntermediateDirectories: true
                )
                let imageURL = folder.appendingPathComponent(
                    "\(identifier.id).tiff", isDirectory: false
                )
                guard let nsImage = NSImage(data: imageData) else {
                    Loggers.images.error(
                        """
                        couldn't initialize NSImage from data: \(identifier.uri)
                        """
                    )
                    return
                }
                let imageSize: CGFloat =
                        identifier.idCategory == .playlist ? 30 : 64
                guard let resizedImage = nsImage.croppedToSquare()?
                        .resized(width: imageSize, height: imageSize) else {
                    Loggers.images.error(
                        "couldn't crop image: \(identifier.uri)"
                    )
                    return
                            
                }
                let swiftUIImage = Image(nsImage: resizedImage)

                guard let newImageData = resizedImage.tiffRepresentation else {
                    return
                }
                try newImageData.write(to: imageURL)
                Loggers.images.trace(
                    "did save \(identifier.uri) to \(imageURL.path)"
                )
                
                DispatchQueue.main.async {
                    // MARK: Save image to cache
                    self.images[identifier] = swiftUIImage
                    self.objectWillChange.send()
                }
                
            } catch {
                Loggers.images.error(
                    "couldn't save image \(identifier.uri) to file: \(error)"
                )
            }
            
        }

    }
    
    /// Delete images which have been downloaded, but are no longer part of the
    /// user's playlists or saved albums.
    func deleteUnusedImagesIfNeeded() {

        if let date = self.lastTimeDeletedUnusedImages {
            // only delete images every hour
            if date.addingTimeInterval(3_600) > Date() {
                Loggers.images.trace("will NOT delete unused images")
                return
            }
        }

        self.lastTimeDeletedUnusedImages = Date()

        Loggers.images.notice("WILL delete unused images")

        let items = [
            (
                self.imageFolderURL(for: .playlist),
                Set(self.playlists.map(\.id))
            ),
            (
                self.imageFolderURL(for: .album),
                Set(self.savedAlbums.compactMap(\.id))
            )
        ]
        
        for (folder, ids) in items {
            
            guard let folder = folder else {
                continue
            }
            
            if ids.isEmpty {
                continue
            }
            
            do {
                for file in try FileManager.default.contentsOfDirectory(
                    at: folder,
                    includingPropertiesForKeys: [],
                    options: .skipsHiddenFiles
                ) {
                    let fileName = file.lastPathComponent
                    if let id = try! fileName.regexMatch(#"(.+)\.\w+"#)?
                            .groups.first??.match {
                        
                        if !ids.contains(id) {
                            let imageURL = folder.appendingPathComponent(
                                fileName
                            )
                            Loggers.images.notice(
                                "will remove image at \(imageURL)"
                            )
                            try FileManager.default.removeItem(at: imageURL)
                        }
                        
                    }
                    else {
                        Loggers.images.error("couldn't get id for file \(file)")
                    }
                }
                
            } catch {
                Loggers.images.error("couldn't delete unused images: \(error)")
            }
            
        }

    }

    func deleteExtraQueueItemImagesIfNeeded() {
        
        if let date = self.lastTimeDeletedExtraQueueImages {
            // only delete images every 15 minutes
            if date.addingTimeInterval(900) > Date() {
                Loggers.images.trace("will NOT delete extra queue item images")
                return
            }
        }

        self.lastTimeDeletedExtraQueueImages = Date()
        
        Loggers.images.notice("WILL delete extra queue item images")

        let max = 50

        if self.queueItemImages.count <= max {
            return
        }

        let deleteCount = self.queueItemImages.count - max


        // delete images with lower dates
        
        let toDelete = self.queueItemImages.sorted { lhs, rhs in
            lhs.value.lastAccessed < rhs.value.lastAccessed
        }
        .map(\.key)
        .prefix(deleteCount)
        
        Loggers.images.notice(
            """
            will delete \(deleteCount) queue item images: \
            \(toDelete.map(\.uri))
            """
        )

        for identifier in toDelete {
            self.queueItemImages[identifier] = nil
        }
 
    }

    /// Removes the folder containing the images and removes all items from the
    /// `images` and `queueItemImages` libraryPageTransitiondictionary.
    func removeImagesCache() {
        self.images = [:]
        self.queueItemImages = [:]
        do {
            if let folder = self.imagesFolder {
                Loggers.images.notice("will delete folder: \(folder)")
                try FileManager.default.removeItem(at: folder)
            }
            
        } catch {
            Loggers.images.error(
                "couldn't remove image cache: \(error)"
            )
        }
    }

    // MARK: - Open -

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
        // Ensure the Spotify application is active before opening the URL
        self.openSpotifyDesktopApplication { _, _ in
            NSWorkspace.shared.open(uriURL)
        }

    }
    
    func openAlbumInSpotify() {
        
        self.openAlbumCancellable = self.syncedCurrentlyPlayingContext
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "openAlbumInSpotify error: \(error)"
                        )
                    }
                },
                receiveValue: { context in
                    
                    guard case .track(let track) = context?.item else {
                        return
                    }
                    guard let albumURI = track.album?.uri,
                            let url = URL(string: albumURI) else {
                        return
                    }

                    // Ensure the Spotify application is active before
                    // opening the URL
                    self.openSpotifyDesktopApplication { _, _ in
                        NSWorkspace.shared.open(url)
                    }
                }
            )

    }

    /// Open the current artist/show in the browser.
    func openArtistOrShowInSpotify() {
        
        self.openArtistOrShowCancellable = self.syncedCurrentlyPlayingContext
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        Loggers.playerManager.error(
                            "openArtistOrShowInBrowser error: \(error)"
                        )
                    }
                },
                receiveValue: { context in
                    
                    guard let uri = context?.showOrArtistIdentifier?.uri,
                            let url = URL(string: uri) else {
                        return
                    }

                    // Ensure the Spotify application is active before
                    // opening the URL
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

    // MARK: - Key Events -
    
    /// Returns `true` if the key event was handled; else, `false`.
    func receiveKeyEvent(
        _ event: NSEvent,
        requireModifierKey: Bool
    ) -> Bool {
        
        Loggers.keyEvent.trace("PlayerManager: \(event)")

        // 49 == space
        if !requireModifierKey && event.keyCode == 49 {
            self.playPause()
            return true
        }

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
        
        Loggers.keyEvent.trace("shortcut: \(shortcut); name: \(shortcutName)")
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
            case .volumeDown:
                Loggers.keyEvent.trace("decrease sound volume")
                let newSoundVolume = (self.soundVolume - 5)
                    .clamped(to: 0...100)
                self.soundVolume = newSoundVolume
            case .showLibrary:
                if self.isShowingLibraryView {
                    self.dismissLibraryView(animated: true)
                }
                else {
                    self.presentLibraryView()
                }
             case .repeatMode:
                self.cycleRepeatMode()
            case .shuffle:
                self.toggleShuffle()
            case .likeTrack:
                self.currentTrackIsSaved.toggle()
                self.addOrRemoveCurrentTrackFromSavedTracks()
            case .onlyShowMyPlaylists:
                self.onlyShowMyPlaylists.toggle()
                Loggers.keyEvent.notice(
                    "onlyShowMyPlaylists = \(self.onlyShowMyPlaylists)"
                )
            case .settings:
                AppDelegate.shared.openSettingsWindow()
            case .quit:
                NSApplication.shared.terminate(nil)
            case .undo:
                if self.undoManager.canUndo {
                    self.undoManager.undo()
                }
                else {
                    return false
                }
            case .redo:
                if self.undoManager.canRedo {
                    self.undoManager.redo()
                }
                else {
                    return false
                }
            default:
                return false
        }
        return true
    }

    func presentLibraryView() {
        self.playerViewIsFirstResponder = false
        self.retrievePlaylists()
        self.retrieveSavedAlbums()
        self.retrieveCurrentlyPlayingContext()
        self.retrieveQueue()
        
        os_signpost(
            .event,
            log: Self.osLog,
            name: "present library view"
        )

        withAnimation(PlayerView.animation) {
            self.isShowingLibraryView = true
        }
        
        switch self.libraryPage {
            case .playlists:
                self.queueViewIsFirstResponder = false
                self.savedAlbumsGridViewIsFirstResponder = false
                self.playlistsScrollViewIsFirstResponder = true
            case .albums:
                self.queueViewIsFirstResponder = false
                self.playlistsScrollViewIsFirstResponder = false
                self.savedAlbumsGridViewIsFirstResponder = true
            case .queue:
                self.playlistsScrollViewIsFirstResponder = false
                self.savedAlbumsGridViewIsFirstResponder = false
                self.queueViewIsFirstResponder = true
        }
    }

    func dismissLibraryView(animated: Bool) {
        
        os_signpost(
            .event,
            log: Self.osLog,
            name: "dismiss library view"
        )

        if animated {
            withAnimation(PlayerView.animation) {
                self.isShowingLibraryView = false
            }
            self.updateSoundVolumeAndPlayerPosition()
            self.retrieveAvailableDevices()
            
            // If `animated == false`, then the popover has been closed and this
            // work will be done in the `popoverDidClose` sink in `.init`.
            self.commitModifiedDates()
            DispatchQueue.main.asyncAfter(
                deadline: .now() + PlayerView.animationDuration
            ) {
                self.sortPlaylistsByLastModifiedDate(&self.playlists)
                self.sortAlbumsByLastModifiedDate(&self.savedAlbums)
            }
        }
        else {
            self.isShowingLibraryView = false
        }

        self.didScrollToAlbumsSearchBar = false
        self.didScrollToPlaylistsSearchBar = false
        
        self.savedAlbumsGridViewIsFirstResponder = false
        self.playlistsScrollViewIsFirstResponder = false
        self.queueViewIsFirstResponder = false
        self.playerViewIsFirstResponder = true
    }
    
    func commitModifiedDates() {
        self.committedPlaylistsLastModifiedDates = self.playlistsLastModifiedDates
        self.committedAlbumsLastModifiedDates = self.albumsLastModifiedDates
    }

}

// MARK: - Private Members -

private extension PlayerManager {
    
    private func receiveCurrentlyPlayingContext(
        _ context: CurrentlyPlayingContext?
    ) {
        
        guard let context = context else {
            self.currentlyPlayingContext = nil
            return
        }
        
        Loggers.playerState.trace(
            """
            CurrentlyPlayingContext.context.uri: \
            \(context.context?.uri ?? "nil")
            """
        )

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
        self.storedSyncedCurrentlyPlayingContext = context
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

//        self.retrieveCurrentlyPlayingPlaylist()
        
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
            case (nil, nil):
                return lhs.index < rhs.index
        }
    }
    
    func debug() {
        
        self.$savedAlbumsGridViewIsFirstResponder.sink { isFirstResponder in
            Loggers.firstResponder.trace(
                "savedAlbumsGridViewIsFirstResponder: \(isFirstResponder)"
            )
        }
        .store(in: &self.cancellables)
        
        self.$playlistsScrollViewIsFirstResponder.sink { isFirstResponder in
            Loggers.firstResponder.trace(
                "playlistsScrollViewIsFirstResponder: \(isFirstResponder)"
            )
        }
        .store(in: &self.cancellables)
        
    }

}
