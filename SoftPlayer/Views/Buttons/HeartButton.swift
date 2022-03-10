import SwiftUI

struct HeartButton: View {
    
    @Binding var isHearted: Bool

    let action: () -> Void
    
    @State var unlikeAnimationProgress: CGFloat = 1
    let unlikeAnimation = Animation.linear(duration: 0.4)

    let likeAnimation = Animation.easeOut(duration: 0.7)
    @State var likeAnimationProgress: CGFloat = 1

    let scaleAnimation = Animation.easeOut(duration: 0.2)

    @State private var fillShape = false

    @State private var isScaled = false

    init(isHearted: Binding<Bool>, action: @escaping () -> Void) {
        self._isHearted = isHearted
        self.action = action
    }

    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            HeartShape()
                .inset(by: frame.width * 0.1)
                .scale(isScaled ? 0.9 : 1)
                .style(
                    fill: fillShape ? .green : .clear,
                    stroke: fillShape ? .clear : .primary,
                    lineWidth: lineWidth(geometry)
                )
                .modifier(
                    WaveEffect(
                        center: frame.center,
                        amount: frame.height * 0.1,
                        angle: .degrees(22.5),
                        shakes: 2,
                        progress: unlikeAnimationProgress
                    )
                )
                .versionedBackground {
                    BubblingHeartsView(
                        animationProgress: likeAnimationProgress
                    )
                }
                .versionedOverlay {
                    Circle()
                        .scale(circleScale())
                        .stroke(
                            .green,
                            lineWidth: circleLineWidth(geometry)
                        )
                        .opacity(circleOpacity())
                    Circle()
                        .scale(circleScale() * 0.8)
                        .stroke(
                            .green,
                            lineWidth: circleLineWidth(geometry)
                        )
                        .opacity(circleOpacity())
                }
                .handleMouseEvents(
                    mouseDown: mouseDown(nsView:event:),
                    mouseUp: mouseUp(nsView:event:)
                )
        }
        .aspectRatio(1, contentMode: .fit)
//        .border(Color.primary)
        .onAppear(perform: onAppear)
        .onChange(of: isHearted) { isLiked in
            self.fillShape = isLiked
        }
    }
    
    func circleLineWidth(_ geometry: GeometryProxy) -> CGFloat {
        let base = geometry.size.width * 0.05
        return base * (1 - self.likeAnimationProgress)
    }

    func lineWidth(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width * 0.05
    }
    
    func circleScale() -> CGFloat {
        return 0.5 + self.likeAnimationProgress * 0.5
    }
    
    func circleOpacity() -> CGFloat {
        if self.likeAnimationProgress <= 0.5 {
            return 1
        }
        let normalizedProgress = 1 - (self.likeAnimationProgress - 0.5) * 2
        return normalizedProgress
    }
    
    func onAppear() {
        self.fillShape = self.isHearted
    }

    func mouseDown(nsView: NSView, event: NSEvent) {
//        if self.isLiked {
//            self.fillShape = false
//        }
        self.fillShape = !self.isHearted
//        if !self.isLiked {
        withAnimation(self.scaleAnimation) {
            self.isScaled = true
        }
//        }
    }
    
    func mouseUp(nsView: NSView, event: NSEvent) {
        guard let windowLocation = nsView.window?
                .mouseLocationOutsideOfEventStream else {
            return
        }
        let mouseLocation = nsView.convert(windowLocation, from: nil)
        
        let mouseIsInView = nsView.isMousePoint(
            mouseLocation, in: nsView.frame
        )
        
//        print("mouse up: mouseIsInView: \(mouseIsInView)")
        withAnimation(self.scaleAnimation) {
            self.isScaled = false
        }

        if mouseIsInView {
            self.didTap()
        }
        else {
            self.fillShape = self.isHearted
        }
              
    }

    func didTap() {
        if self.isHearted {
            self.unlikeAnimationProgress = 0
            withAnimation(self.unlikeAnimation) {
                self.unlikeAnimationProgress = 1
            }
        }
        else {
            self.likeAnimationProgress = 0
            withAnimation(self.likeAnimation) {
                self.likeAnimationProgress = 1
            }
        }
        self.isHearted.toggle()
        self.action()
    }
    
    
    
}

struct WaveEffect: GeometryEffect {
    
    let center: CGPoint
    let amount: CGFloat
    let angle: Angle
    let shakes: CGFloat
    var progress: CGFloat

    init(
        center: CGPoint,
        amount: CGFloat,
        angle: Angle,
        shakes: CGFloat,
        progress: CGFloat
    ) {
        self.center = center
        self.amount = amount
        self.angle = angle
        self.shakes = shakes
        self.progress = progress
    }

    var animatableData: CGFloat {
        get { self.progress }
        set { self.progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        
        let delta = self.progress * .pi * CGFloat(self.shakes * 2)

        let translationPercent = sin(delta)

        let rotationPercent = -0.5 * cos(delta) + 0.5

        let translation = self.amount * translationPercent
        let rotation = rotationPercent * self.angle.radians

        let translationTransform = CGAffineTransform(
            translationX: translation, y: 0
        )
        
        let rotationTransform = CGAffineTransform(
            rotationAngle: rotation, anchor: self.center
        )

        let transform = rotationTransform.concatenating(translationTransform)

        return ProjectionTransform(transform)
    }
}

@available(macOS 12.0, *)
struct HeartButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartButton(isHearted: .constant(true), action: { })
                .background()
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
            HeartButton(isHearted: .constant(false), action: { })
                .background()
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)
        }
        .frame(width: 200, height: 200)
    }
}
