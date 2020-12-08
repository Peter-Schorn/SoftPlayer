import Foundation
import SpotifyWebAPI
import Combine
import SwiftUI

extension Publisher {
    
    func handleAuthenticationError(
        spotify: Spotify
    ) -> Publishers.TryCatch<Self, Empty<Self.Output, Error>> {
        
        return self.tryCatch { error -> Empty<Output, Error> in
            if let authError = error as? SpotifyAuthenticationError,
                   authError.error == "invalid_grant"
                   {
                spotify.isAuthorized = false
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
        return newPercent * (new.upperBound - new.lowerBound) + new.lowerBound
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

extension NSImage {
    
    /// [Source](https://gist.github.com/musa11971/62abcfda9ce3bb17f54301fdc84d8323)
    var averageColor: NSColor? {
        
        // Image is not valid, so we cannot get the average color
        if !isValid { return nil }
        
        // Create a CGImage from the NSImage
        var imageRect = CGRect(
            x: 0,
            y: 0,
            width: self.size.width,
            height: self.size.height
        )
        let cgImageRef = self.cgImage(
            forProposedRect: &imageRect,
            context: nil,
            hints: nil
        )
        
        // Create vector and apply filter
        let inputImage = CIImage(cgImage: cgImageRef!)
        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )
        
        let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [
                kCIInputImageKey: inputImage,
                kCIInputExtentKey: extentVector
            ]
        )
        let outputImage = filter!.outputImage!
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        
        return NSColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
        
    }
}
