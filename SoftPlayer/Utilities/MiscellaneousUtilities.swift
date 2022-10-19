import Foundation
import SpotifyWebAPI
import RegularExpressions
import Combine
import SwiftUI
import AppKit

enum Size {
    case small, large
}

extension Publisher {
    
    func handleAuthenticationError(
        spotify: Spotify
    ) -> Publishers.TryCatch<Self, Empty<Self.Output, Error>> {
        
        return self.tryCatch { error -> Empty<Output, Error> in
            if let authError = error as? SpotifyAuthenticationError,
                    authError.error == "invalid_grant" {
                spotify.api.authorizationManager.deauthorize()
                return Empty()
            }
            throw error
        }

    }

}


extension DateComponentsFormatter {
    
    static let playbackTimeWithHours: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    static let playbackTime: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    

}

extension ProcessInfo {
    
    /// Whether or not this process is running within the context of
    /// an Xcode preview.
    var isPreviewing: Bool {
        return self.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

}

/// Returns the largest element, with `nil` being considered the smallest,
/// meaning that if one parameter is `nil` and the other is non-`nil`, then
/// the non-`nil` parameter will always be returned.
/// If both `lhs` and `rhs` are `nil`, then returns `nil`.
func maxNilSmallest<T: Comparable>(_ lhs: T?, _ rhs: T?) -> T? {
    switch (lhs, rhs) {
        case (.some(let lhs), .some(let rhs)):
            return max(lhs, rhs)
        case (.some(let t), nil), (nil, .some(let t)):
            return t
        default:
            return nil
    }
}

extension String {
    
    /// An array of all the words in the string.
    var words: [String] {
        return try! self.regexSplit("\\W+", ignoreIfEmpty: true)
    }

}


extension Comparable {
    
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(range.upperBound, max(range.lowerBound, self))
    }

}

extension CGFloat {
    
    func map(
        from old: ClosedRange<CGFloat>,
        to new: ClosedRange<CGFloat>
    ) -> CGFloat {
        let oldMagnitude = old.upperBound - old.lowerBound
        let newPercent = (self - old.lowerBound) / oldMagnitude
        let newMagnitude = new.upperBound - new.lowerBound
        let result = newPercent * newMagnitude + new.lowerBound
        return result.isFinite ? result : 0
    }
}

extension Color {
    
    static let playbackPositionLeadingRectangle = Color.init(
        NSColor(named: .init("playbackPositionLeadingRectangle"))!
    )
    
    static let sliderTrailingRectangle = Color.init(
        NSColor(named: .init("sliderTrailingRectangle"))!
    )
    
}

extension Error {
    
    var customizedLocalizedDescription: String {
        if case .httpError(let data, _) = self as? SpotifyGeneralError,
                let dataString = String(data: data, encoding: .utf8),
                dataString.lowercased().starts(with: "user not approved for app") {
            return dataString
        }
        
        return NSLocalizedString(self.localizedDescription, comment: "")
    }
    
}

extension URL {
    
    /// http://www.example.com/
    static let example = Self(string: "http://www.example.com/")!

}

enum LibraryPage: String {
    
    case playlists
    case albums
    case queue
    
    var index: Int {
        switch self {
            case .playlists:
                return 0
            case .albums:
                return 1
            case .queue:
                return 2
        }
    }

}

extension Notification.Name {
    static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}

extension Sequence where Element: Hashable {
    
    var containsDuplicates: Bool {
        var seen = Set<Element>()
        return !self.allSatisfy { seen.insert($0).inserted }
    }
}

extension CGRect {
    
    var center: CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
    
    func croppedToSquare() -> CGRect {
        
        if self.width == self.height {
            return self
        }
        
        else {
            let smallestDimension = min(self.width, self.height)
            
            return CGRect(
                x: self.minX + (self.width - smallestDimension) / 2,
                y: self.minY + (self.height - smallestDimension) / 2,
                width: smallestDimension,
                height: smallestDimension
            )
        }
    }
    
}

extension CGAffineTransform {
    
    init(rotationAngle: CGFloat, anchor: CGPoint) {
        self.init(
            a: cos(rotationAngle),
            b: sin(rotationAngle),
            c: -sin(rotationAngle),
            d: cos(rotationAngle),
            tx: anchor.x - anchor.x * cos(rotationAngle) + anchor.y * sin(rotationAngle),
            ty: anchor.y - anchor.x * sin(rotationAngle) - anchor.y * cos(rotationAngle)
        )
    }

    func rotated(by angle: CGFloat, anchor: CGPoint) -> Self {
        let transform = Self(rotationAngle: angle, anchor: anchor)
        return self.concatenating(transform)
    }

}

extension String {
    
    var isSavedTracksURI: Bool {
        let pattern = try! Regex("^spotify:user:.+:collection$")
        return try! self.regexMatch(pattern) != nil
        
    }

}

extension URL {
    
    static let savedTracksURL = Self(
        string: "https://open.spotify.com/collection/tracks"
    )!

}

extension NSEvent.ModifierFlags {
    
    /// The modifier keys that should be present in a keyboard shortcut:
    /// control, option and command.
    static let shortchutModifiers: Self = [
        .control,
        .option,
        .command
    ]

}
