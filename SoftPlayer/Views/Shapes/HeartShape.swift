import SwiftUI

struct HeartShape: InsettableShape {
    
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: self.inset, dy: self.inset)
        let squareRect = insetRect.croppedToSquare()
        return self.pathInRectCore(squareRect)
    }
    
    func inset(by amount: CGFloat) -> Self {
        var copy = self
        copy.inset += amount
        return copy
    }
    
    func pathInRectCore(_ rect: CGRect) -> Path {
        
        var path = Path()

        // Calculate Radius of Arcs using the Pythagorean theorem
        let sideOne = rect.width * 0.4
        let sideTwo = rect.height * 0.3
        let arcRadius = sqrt(sideOne * sideOne + sideTwo * sideTwo) / 2
        
        // Left Hand Curve
        path.addArc(
            center: CGPoint(
                x: rect.minX + rect.width * 0.3,
                y: rect.minY + rect.height * 0.35
            ),
            radius: arcRadius,
            startAngle: .degrees(135),
            endAngle: .degrees(315),
            clockwise: false
        )
        
        // Top Centre Dip
        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width / 2,
                y: rect.minY + rect.height * 0.2
            )
        )
        
        // Right Hand Curve
        path.addArc(
            center: CGPoint(
                x: rect.minX + rect.width * 0.7,
                y: rect.minY + rect.height * 0.35
            ),
            radius: arcRadius,
            startAngle: .degrees(225),
            endAngle: .degrees(45),
            clockwise: false
        )
        
        // Right Bottom Line
        path.addLine(
            to: CGPoint(
                x: rect.minX + rect.width * 0.5,
                y: rect.minY + rect.height * 0.95
            )
        )
        
        // Left Bottom Line
        path.closeSubpath()
        
        // MARK: Debug
//        path.addRect(rect)

        return path

    }

}

struct HeartShape_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartShape()
//                .inset(by: 50)
                .strokeBorder(Color.primary, lineWidth: 10)
                .padding(2)
                .border(Color.green, width: 2)
            Group {
                Image(systemName: "heart")
                Image(systemName: "heart.fill")
            }
            .font(.largeTitle)
            .scaleEffect(5)
            .padding(50)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
