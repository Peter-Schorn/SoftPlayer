import SwiftUI

struct BubblingHeartsView: View, Animatable {
    
    var animationProgress: CGFloat

    var animatableData: CGFloat {
        get { self.animationProgress }
        set { self.animationProgress = newValue }
    }

    let sizeMultiplier: CGFloat = 0.6

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HeartShape()
                    .fill(Color.gray)
//                    .overlay {
//                        Text("1")
//                    }
                    .frame(
                        width: geometry.size.height * sizeMultiplier,
                        height: geometry.size.width * sizeMultiplier
                    )
                    .position(heartPosition1(geometry))
                    .opacity(heartOpacity1())
                HeartShape()
                    .fill(Color.gray)
//                    .overlay {
//                        Text("2")
//                    }
                    .frame(
                        width: geometry.size.height * sizeMultiplier,
                        height: geometry.size.width * sizeMultiplier
                    )
                    .position(heartPosition2(geometry))
                    .opacity(heartOpacity2())
                HeartShape()
                    .fill(Color.green)
//                    .overlay {
//                        Text("3")
//                    }
                    .frame(
                        width: geometry.size.height * sizeMultiplier,
                        height: geometry.size.width * sizeMultiplier
                    )
                    .position(heartPosition3(geometry))
                    .opacity(heartOpacity3())
                HeartShape()
                    .fill(Color.green)
//                    .overlay {
//                        Text("4")
//                    }
                    .frame(
                        width: geometry.size.height * sizeMultiplier,
                        height: geometry.size.width * sizeMultiplier
                    )
                    .position(heartPosition4(geometry))
                    .opacity(heartOpacity4())
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    func heartOpacity1() -> CGFloat {
        if self.animationProgress <= 0.5 {
            return 1
        }
        return 2 * (1 - (self.animationProgress))
    }
    
    func heartOpacity2() -> CGFloat {
        if self.animationProgress <= 0.5 {
            return 1
        }
        let progress = min(1, self.animationProgress * 1.5)
        return 4 * (1 - progress)
    }
    
    func heartOpacity3() -> CGFloat {
        if self.animationProgress <= 0.5 {
            return 1
        }
        let progress = min(1, self.animationProgress * 1.2)
        return 2.5 * (1 - progress)
    }
    
    func heartOpacity4() -> CGFloat {
        if self.animationProgress <= 0.5 {
            return 1
        }
//        return max(0, 3 * (1 - self.animationProgress) - 0.5)
        return 2 * (1 - self.animationProgress)
    }

    func heartPosition1(_ geoemtry: GeometryProxy) -> CGPoint {
        let frame = geoemtry.frame(in: .local)
        
        let centerXOffsetPercent = self.animationProgress
        let centerYOffsetPercent = pow(self.animationProgress, 2)

        let centerXOffset = centerXOffsetPercent * frame.width
        let centerYOffset = centerYOffsetPercent * frame.height

        return CGPoint(
            x: frame.midX - centerXOffset,
            y: frame.midY - centerYOffset
        )
    }
    
    func heartPosition2(_ geoemtry: GeometryProxy) -> CGPoint {
        let frame = geoemtry.frame(in: .local)
        
        let progress = min(1, self.animationProgress * 1.5)
        let centerXOffsetPercent = 0.7 * progress
        let centerYOffsetPercent = pow(progress, 2)

        let centerXOffset = centerXOffsetPercent * frame.width
        let centerYOffset = centerYOffsetPercent * frame.height

        return CGPoint(
            x: frame.midX + centerXOffset,
            y: frame.midY - centerYOffset
        )
    }
    
    func heartPosition3(_ geoemtry: GeometryProxy) -> CGPoint {
        let frame = geoemtry.frame(in: .local)
        
        let progress = min(1, self.animationProgress * 1.2)
        let centerXOffsetPercent = 0.5 * progress / 2
        let centerYOffsetPercent = 4 * pow(progress / 2, 2)

        let centerXOffset = centerXOffsetPercent * frame.width
        let centerYOffset = centerYOffsetPercent * frame.height

        return CGPoint(
            x: frame.midX - centerXOffset,
            y: frame.midY - centerYOffset
        )
    }
    
    func heartPosition4(_ geoemtry: GeometryProxy) -> CGPoint {
        let frame = geoemtry.frame(in: .local)
        
        let progress = self.animationProgress * 0.9
        let centerXOffsetPercent = progress / 2
        let centerYOffsetPercent = 4 * pow(progress / 2, 2)

        let centerXOffset = centerXOffsetPercent * frame.width
        let centerYOffset = centerYOffsetPercent * frame.height

        return CGPoint(
            x: frame.midX + centerXOffset,
            y: frame.midY - centerYOffset
        )
    }
    
    
}


#if compiler(>=5.4)
@available(macOS 12.0, *)
struct BubblingHeartsView_Previews: PreviewProvider {
    
    struct Preview: View {
        
        @State var animationProgress: CGFloat = 0

        var body: some View {
            VStack {
                BubblingHeartsView(animationProgress: animationProgress)
                    .border(.green, width: 2)
                    .padding()
                Text(
                    animationProgress,
                    format: FloatingPointFormatStyle()
                        .precision(.fractionLength(3))
                )
                Slider(
                    value: $animationProgress,
                    in: 0...1
                )
                .padding([.horizontal, .bottom])
            }
            .padding()
            .frame(width: 400, height: 600)
            .background(
                Rectangle()
                    .fill(BackgroundStyle())
            )
            .preferredColorScheme(.light)
            .previewLayout(.sizeThatFits)
//            .onAppear {
//                let animation = Animation
//                    .linear(duration: 2)
//                    .repeatForever(autoreverses: false)
//                withAnimation(animation) {
//                    self.animationProgress = 1
//                }
//            }
        }
    }

    static var previews: some View {
        Preview()
    }
}
#endif
