import Foundation
import SwiftUI

// MARK: Images

/// The names of the image assets.
enum ImageName: String {
    
    case spotifyLogoGreen = "spotify logo green"
    case spotifyLogoWhite = "spotify logo white"
    case spotifyLogoBlack = "spotify logo black"
    case spotifyAlbumPlaceholder = "spotify album placeholder"
}

extension Image {
    
    /// Creates an image using `ImageName`, an enum which contains the
    /// names of all the image assets.
    init(_ name: ImageName) {
        self.init(name.rawValue)
    }
    
}

extension NSImage {
    
    /// Creates an image using `ImageName`, an enum which contains the
    /// names of all the image assets.
    convenience init?(_ name: ImageName) {
        self.init(named: name.rawValue)
    }
    
}

// MARK: Colors

extension Color {
    
    static let playbackPositionLeadingRectangle = Color.init(
        "playbackPositionLeadingRectangle"
    )
    
    static let sliderTrailingRectangle = Color.init(
        "sliderTrailingRectangle"
    )
 
    static let lightGreen = Color("lightGreen")

}
