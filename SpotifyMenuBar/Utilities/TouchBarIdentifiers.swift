import AppKit

extension NSTouchBarItem.Identifier {
    
    static let playlistsScrubber = NSTouchBarItem.Identifier(
        "playlistsScrubber"
    )
    static let playlistsScrollView = NSTouchBarItem.Identifier(
        "playlistsScrollView"
    )
    
}

extension NSTouchBar.CustomizationIdentifier {
    
    static let playlists = NSTouchBar.CustomizationIdentifier(
        "playlists"
    )
    
}

extension NSUserInterfaceItemIdentifier {
    
    static let playlistsScrubberItem = Self("playlistsScrubberItem")
    static let playlistsScrollViewItem = Self("playlistsScrubberItem")

}
