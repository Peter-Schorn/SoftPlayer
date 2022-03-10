import SwiftUI

extension Shape {
    
    /// Fills and strokes a shape.
    func style<F: ShapeStyle, S: ShapeStyle>(
        fill: F,
        stroke: S,
        strokeStyle: StrokeStyle
    ) -> some View {
        ZStack {
            self.fill(fill)
            self.stroke(stroke, style: strokeStyle)
        }
    }
    
    /// Fills and strokes a shape.
    func style<F: ShapeStyle, S: ShapeStyle>(
        fill: F,
        stroke: S,
        lineWidth: CGFloat = 1
    ) -> some View {
        self.style(
            fill: fill,
            stroke: stroke,
            strokeStyle: StrokeStyle(lineWidth: lineWidth)
        )
    }
    
}

extension InsettableShape {
    
    /// Fills and strokes an insettable shape.
    func style<F: ShapeStyle, S: ShapeStyle>(
        fill: F,
        strokeBorder: S,
        strokeStyle: StrokeStyle
    ) -> some View {
        ZStack {
            self.fill(fill)
            self.strokeBorder(strokeBorder, style: strokeStyle)
        }
    }
    
    /// Fills and strokes an insettable shape.
    func style<F: ShapeStyle, S: ShapeStyle>(
        fill: F,
        strokeBorder: S,
        lineWidth: CGFloat = 1
    ) -> some View {
        self.style(
            fill: fill,
            strokeBorder: strokeBorder,
            strokeStyle: StrokeStyle(lineWidth: lineWidth)
        )
    }
    
}
