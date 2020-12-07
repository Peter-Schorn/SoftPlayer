import SwiftUI

struct CustomSliderView: View {
    
    @Binding var value: CGFloat
    @Binding var isDragging: Bool
    
    @State var lastOffset: CGFloat = 0
    
    let range: ClosedRange<CGFloat>
    let knobDiameter: CGFloat
    let knobScaleEffectMagnitude: CGFloat
    let leadingRectangleColor: Color

    /// Called when the drag gesture ends.
    let onEnded: ((DragGesture.Value) -> Void)?

    let sliderHeight: CGFloat = 5

    let knobAnimation = Animation.linear(duration: 0.1)
    let knobTransition = AnyTransition.scale
    
    init(
        value: Binding<CGFloat>,
        isDragging: Binding<Bool>,
        range: ClosedRange<CGFloat>,
        knobDiameter: CGFloat,
        knobScaleEffectMagnitude: CGFloat = 1,
        leadingRectangleColor: Color,
        onEnded: ((DragGesture.Value) -> Void)? = nil
    ) {
        self._value = value
        self._isDragging = isDragging
        self.range = range
        self.knobDiameter = knobDiameter
        self.knobScaleEffectMagnitude = knobScaleEffectMagnitude
        self.leadingRectangleColor = leadingRectangleColor
        self.onEnded = onEnded
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    // MARK: Leading Rectangle
                    Capsule()
                        .fill(leadingRectangleColor)
                        .frame(
                            width: leadingRectangleWidth(geometry),
                            height: sliderHeight
                        )
                    // MARK: Trailing Rectangle
                    Capsule()
                        .fill(Color.primary.opacity(0.25))
//                        .fill(Color.sliderTrailingRectangle)
                        .frame(height: sliderHeight)
                }
                HStack(spacing: 0) {
                    // MARK: Knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: knobDiameter)
                        .scaleEffect(isDragging ? knobScaleEffectMagnitude : 1)
                        .shadow(radius: 5)
                        .transition(knobTransition)
                        .offset(x: knobOffset(geometry))
                        .gesture(knobDragGesture(geometry))
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(knobPositionDragGesture(geometry))
        }
        .frame(height: knobDiameter + 7)
        .padding(.horizontal, 5)

    }
    
    func knobOffset(_ geometry: GeometryProxy) -> CGFloat {
        let maxKnobOffset = geometry.size.width - self.knobDiameter
        return max(0, self.value.map(from: self.range, to: 0...maxKnobOffset))
    }
    
    func leadingRectangleWidth(_ geometry: GeometryProxy) -> CGFloat {
        return max(0, knobOffset(geometry) + knobDiameter / 2)
    }
    
    func knobDragGesture(_ geometry: GeometryProxy) -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { dragValue in

                withAnimation(knobAnimation) {
                    self.isDragging = true
                }
                
                if abs(dragValue.translation.width) < 0.1 {
                    self.lastOffset = knobOffset(geometry)
                }
                
                let knobOffsetMin: CGFloat = 0
                let knobOffsetMax = geometry.size.width - self.knobDiameter
                let knobOffsetRange = knobOffsetMin...knobOffsetMax
                let offset = self.lastOffset + dragValue.translation.width
                let knobOffset = offset.clamped(to: knobOffsetRange)
                self.value = knobOffset.map(
                    from: knobOffsetRange,
                    to: self.range
                )
//                print("value: \(self.value)")
                
            }
            .onEnded { dragValue in
                self.isDragging = false
                self.onEnded?(dragValue)
            }
    }
    
    func knobPositionDragGesture(_ geometry: GeometryProxy) -> some Gesture {
        return DragGesture(minimumDistance: 0)
            .onChanged { dragValue in
                
                withAnimation(knobAnimation) {
                    self.isDragging = true
                }
                
                let knobOffsetMin = knobDiameter / 2
                let knobOffsetMax = geometry.size.width - knobDiameter / 2
                let knobOffsetRange = knobOffsetMin...knobOffsetMax
                let knobOffset = dragValue.location.x
                    .clamped(to: knobOffsetRange)
                self.value = knobOffset.map(
                    from: knobOffsetRange,
                    to: self.range
                )
//                print("value: \(self.value)")

            }
            .onEnded { dragValue in
                self.isDragging = false
                self.onEnded?(dragValue)
            }
    }
    
}

struct PlayerPositionSliderView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView_Previews.previews
    }
}
