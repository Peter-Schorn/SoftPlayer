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

enum LibraryPage: Int {
    case playlists
    case albums
}

extension Binding where Value: RawRepresentable {
    
    var rawValueBinding: Binding<Value.RawValue> {
        
        return Binding<Value.RawValue>(
            get: {
                return self.wrappedValue.rawValue
            },
            set: { newValue in
                self.wrappedValue = Value(rawValue: newValue)!
            }
        )
        
    }

}

extension Notification.Name {
    static let shortcutByNameDidChange = Self("KeyboardShortcuts_shortcutByNameDidChange")
}
