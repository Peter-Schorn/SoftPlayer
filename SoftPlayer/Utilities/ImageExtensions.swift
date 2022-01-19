import Foundation
import AppKit

extension NSImage {
    

    func resized(width: CGFloat, height: CGFloat) -> NSImage {
        return self.resized(
            size: CGSize(width: width, height: height)
        )
    }

    func resized(size: CGSize) -> NSImage {
        
        

        let newImage = NSImage.init(size: size)
        newImage.lockFocus()
        self.draw(
            in: CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: size.height
            ),
            from: CGRect(
                x: 0,
                y: 0,
                width: self.size.width,
                height: self.size.height
            ),
            operation: .copy,
            fraction: 1
        )
        newImage.unlockFocus()
        newImage.size = size
        return newImage
    }

    /// [Source](https://gist.github.com/musa11971/62abcfda9ce3bb17f54301fdc84d8323)
    var averageColor: NSColor? {
        
        // Image is not valid, so we cannot get the average color
        if !self.isValid { return nil }
        
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

    /// Returns a new image cropped to a square centered on the original image
    /// and with a length equal to the smallest dimension of the original image.
    func croppedToSquare() -> NSImage? {

        if self.size.width == self.size.height {
            return self
        }

        var originalRect = CGRect(origin: .zero, size: self.size)

        guard let cgImage = self.cgImage(
            forProposedRect: &originalRect,
            context: nil,
            hints: nil
        ) else {
            return nil
        }
        
        let smallestDimension = min(cgImage.width, cgImage.height)
        
        let croppedRect = CGRect(
            x: (cgImage.width - smallestDimension) / 2,
            y: (cgImage.height - smallestDimension) / 2,
            width: smallestDimension,
            height: smallestDimension
        )

        guard let croppedImage = cgImage.cropping(to: croppedRect) else {
            return nil
        }

        return NSImage(
            cgImage: croppedImage,
            size: croppedRect.size
        )
        
    }

}
