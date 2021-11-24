import SwiftUI
import Foundation

struct NowPlayingAnimation: View {
    
    @Binding var isAnimating: Bool

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<3) { i in
                BarView(index: i, isAnimating: $isAnimating)
            }
        }
        
    }

    struct BarView: View {
        
        let index: Int

        @Binding var isAnimating: Bool

        let inactiveAnimation: Animation

        @State private var activeAnimation: Animation

        @State private var scale: CGFloat
        
        @State private var targetScale: CGFloat

        let minScale: CGFloat = 0.2
        let maxScale: CGFloat = 1
        
        let duration: CGFloat = 0.4
        let durationRange = 0.3...0.5

        let delayMultiplier = 0.2

        init(index: Int, isAnimating: Binding<Bool>) {
            self.index = index
            self._isAnimating = isAnimating
            self.scale = self.minScale
            self.targetScale = self.minScale
            
            self.inactiveAnimation = Animation
                .easeInOut(duration: self.duration)

            self.activeAnimation = Animation
                .easeInOut(duration: self.duration)
                .delay(Double(self.index) * delayMultiplier)
                
        }
        
        var body: some View {
            ScalingRectangle(
                scale: scale,
                targetScale: targetScale,
                completion: scalingCompletion
            )
            .fill(Color.green)
            
            .onAppear {
                if self.isAnimating {
                    self.executeAnimation(delay: true)
                }
            }
            .onChange(of: self.isAnimating) { isAnimating in
                
                if isAnimating {
                    self.executeAnimation(delay: true)
                }
                else {
                    withAnimation(self.inactiveAnimation) {
                        self.scale = self.minScale
                        self.targetScale = self.minScale
                    }
                }
                
            }
        }
        
        func scalingCompletion() {
            guard self.isAnimating else { return }

            self.executeAnimation(delay: false)
        }
        
        func executeAnimation(delay: Bool) {
//            print("\n\nexecuteAnimation")
            
            let duration = Double.random(in: durationRange)
//            print("duration: \(duration)")
            
            var animation = Animation
                .easeInOut(duration: duration)
            
            if delay {
                animation = animation
                    .delay(Double(self.index) * delayMultiplier)
            }

            self.activeAnimation = animation

            withAnimation(self.activeAnimation) {
                if scale == self.maxScale {
                    self.scale = self.minScale
                    self.targetScale = self.minScale
                }
                else /* if scale == self.minScale */ {
                    self.scale = self.maxScale
                    self.targetScale = self.maxScale
                }
            }
        }
        
    }

    struct ScalingRectangle: Shape {

        let rectangle = Rectangle()

        private var targetScale: CGFloat
        
        private var scale: CGFloat

        private var completion: () -> Void

        init(
            scale: CGFloat,
            targetScale: CGFloat,
            completion: @escaping () -> Void
        ) {
            self.scale = scale
            self.targetScale = targetScale
            self.completion = completion
        }
        
        var animatableData: CGFloat {
            get {
                return self.scale
            }
            set {
                self.scale = newValue
//                print("value: \(self.scale)")
                self.notifyCompletionIfFinished()
                
            }
        }
        
        func path(in rect: CGRect) -> Path {
            return self.rectangle
                .scale(
                    x: 1,
                    y: scale,
                    anchor: .bottom
                )
                .path(in: rect)
        }

        private func notifyCompletionIfFinished() {

            if self.scale == self.targetScale {
                DispatchQueue.main.async {
                    self.completion()
                }
            }

        }

    }


}


struct NowPlayingAnimation_Previews: PreviewProvider {

    @State static var isPlaying = true

    static var previews: some View {
        NowPlayingAnimation(isAnimating: $isPlaying)
            .contentShape(Rectangle())
            .onTapGesture {
                self.isPlaying.toggle()
            }
            .frame(
                width: 50,
                height: 100
            )
    }

}
