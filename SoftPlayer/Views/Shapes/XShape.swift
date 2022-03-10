import SwiftUI

public struct XShape: InsettableShape {

    public enum Thickness {
        case absolute(CGFloat)
        case relative(CGFloat)
    }
    
    public let thickness: Thickness

    private var inset: CGFloat = 0

    public init(thickness: Thickness = .relative(0.1)) {
        self.thickness = thickness
    }


    public func inset(by amount: CGFloat) -> Self {
        var shape = self
        shape.inset += amount
        return shape
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: self.inset, dy: self.inset)
        let squareRect = insetRect.croppedToSquare()
        return self.pathInRectCore(squareRect)
    }

    /// The rect is already inset and square.
    private func pathInRectCore(_ rect: CGRect) -> Path {
        
        var path = Path()

        let lineWidth: CGFloat
        
        switch thickness {
            case .absolute(let thickness):
                lineWidth = thickness
            case .relative(let thickness):
                lineWidth = rect.width * thickness
        }

        if lineWidth == 0 {
            return path
        }
        
        let circleRadius = lineWidth / 2

        let triangleLeg = sqrt(pow(circleRadius, 2) / 2)
        
        /// The offset from the center for each of the points
        /// near the center of the shape.
        let centerOffset = sqrt(pow(lineWidth, 2) / 2)

        do {
            // MARK: Top Left
            let topLeftCircleCenter = CGPoint(
                x: rect.minX + lineWidth / 2,
                y: rect.minY + lineWidth / 2
            )
            let topLeftCorner1 = CGPoint(
                x: topLeftCircleCenter.x - triangleLeg,
                y: topLeftCircleCenter.y + triangleLeg
            )
//            let topLeftCorner2 = CGPoint(
//                x: topLeftCircleCenter.x + triangleLeg,
//                y: topLeftCircleCenter.y - triangleLeg
//            )
            path.move(to: topLeftCorner1)
            path.addArc(
                center: topLeftCircleCenter,
                radius: circleRadius,
                startAngle: .degrees(135),
                endAngle: .degrees(315),
                clockwise: false
            )

        }
        
        do {
            // MARK: Top Center
            var center = rect.center
            center.y -= centerOffset
            path.addLine(to: center)
            
        }

        do {
            // MARK: Top Right
            let topRightCircleCenter = CGPoint(
                x: rect.maxX - lineWidth / 2,
                y: rect.minY + lineWidth / 2
            )
            let topRightCorner1 = CGPoint(
                x: topRightCircleCenter.x - triangleLeg,
                y: topRightCircleCenter.y - triangleLeg
            )
//            let topRightCorner2 = CGPoint(
//                x: topRightCircleCenter.x + triangleLeg,
//                y: topRightCircleCenter.y + triangleLeg
//            )
            path.addLine(to: topRightCorner1)
            path.addArc(
                center: topRightCircleCenter,
                radius: circleRadius,
                startAngle: .degrees(225),
                endAngle: .degrees(45),
                clockwise: false
            )
        }
        
        
        do {
            // MARK: Right Center
            var center = rect.center
            center.x += centerOffset
            path.addLine(to: center)
        }
        
        do {
            // MARK: Bottom Right
            let bottomRightCircleCenter = CGPoint(
                x: rect.maxX - lineWidth / 2,
                y: rect.maxY - lineWidth / 2
            )
            let bottomRightCorner1 = CGPoint(
                x: bottomRightCircleCenter.x + triangleLeg,
                y: bottomRightCircleCenter.y - triangleLeg
            )
//            let bottomRightCorner2 = CGPoint(
//                x: bottomRightCircleCenter.x - triangleLeg,
//                y: bottomRightCircleCenter.y + triangleLeg
//            )
            path.addLine(to: bottomRightCorner1)
            path.addArc(
                center: bottomRightCircleCenter,
                radius: circleRadius,
                startAngle: .degrees(315),
                endAngle: .degrees(135),
                clockwise: false
            )
        }

        do {
            // MARK: Bottom Center
            var center = rect.center
            center.y += centerOffset
            path.addLine(to: center)
        }
        
        do {
            // MARK: Bottom Left
            let bottomLeftCircleCenter = CGPoint(
                x: rect.minX + lineWidth / 2,
                y: rect.maxY - lineWidth / 2
            )
            let bottomLeftCorner1 = CGPoint(
                x: bottomLeftCircleCenter.x + triangleLeg,
                y: bottomLeftCircleCenter.y + triangleLeg
            )
//            let bottomLeftCorner2 = CGPoint(
//                x: bottomLeftCircleCenter.x - triangleLeg,
//                y: bottomLeftCircleCenter.y - triangleLeg
//            )
            path.addLine(to: bottomLeftCorner1)
            path.addArc(
                center: bottomLeftCircleCenter,
                radius: circleRadius,
                startAngle: .degrees(45),
                endAngle: .degrees(225),
                clockwise: false
            )
        }
        
        do {
            // MARK: Left Center
            var center = rect.center
            center.x -= centerOffset
            path.addLine(to: center)
        }
        
        return path

    }

}

struct XShape_Previews: PreviewProvider {
    static var previews: some View {
        
        XShape()
            .frame(width: 200, height: 200)
            .padding(2)
            .border(Color.green.opacity(0.5), width: 2)
            .padding()
        
    }
}
