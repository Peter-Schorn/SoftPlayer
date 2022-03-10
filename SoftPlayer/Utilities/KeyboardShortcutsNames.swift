import KeyboardShortcuts

extension KeyboardShortcuts.Name {

    static let openApp = Self(
        "openApp", isGlobal: true
    )
    static let showLibrary = Self(
        "showLibrary",
        default: .init(.l, modifiers: [.command])
    )
    static let previousTrack = Self(
        "previousTrack",
        default: .init(.leftArrow, modifiers: [.command])
    )
    static let playPause = Self(
        "playPause",
        default: .init(.k, modifiers: [.command])
    )
    static let nextTrack = Self(
        "nextTrack",
        default: .init(.rightArrow, modifiers: [.command])
    )
    static let repeatMode = Self(
        "repeatMode",
        default: .init(.r, modifiers: [.command])
    )
    static let shuffle = Self(
        "shuffle",
        default: .init(.s, modifiers: [.command])
    )
    static let likeTrack = Self(
        "likeTrack",
        default: .init(.h, modifiers: [.command])
    )
    static let volumeDown = Self(
        "volumeDown",
        default: .init(.downArrow, modifiers: [.command])
    )
    static let volumeUp = Self(
        "volumeUp",
        default: .init(.upArrow, modifiers: [.command])
    )
    static let onlyShowMyPlaylists = Self(
        "onlyShowMyPlaylists",
        default: .init(.m, modifiers: [.command])
    )
    static let settings = Self(
        "settings",
        default: .init(.comma, modifiers: [.command])
    )
    static let quit = Self(
        "quit",
        default: .init(.q, modifiers: [.command])
    )
    static let undo = Self(
        "Undo",
        default: .init(.z, modifiers: [.command])
    )
    static let redo = Self(
        "Redo",
        default: .init(.z, modifiers: [.command, .shift])
    )
    
}
