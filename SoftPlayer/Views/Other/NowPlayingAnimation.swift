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
        
        let minScale: CGFloat = 0.2
        let maxScale: CGFloat = 1

        init(index: Int, isAnimating: Binding<Bool>) {
            self.index = index
            self._isAnimating = isAnimating
            self.scale = self.minScale
            
            self.inactiveAnimation = Animation
                .easeInOut(duration: 0.4)

            self.activeAnimation = Animation
                .easeInOut(duration: 0.4)
                .delay(Double(self.index) * 0.2)
                
        }
        
        var body: some View {
            Rectangle()
                .scale(
                    x: 1,
                    y: scale,
                    anchor: .bottom
                )
                .fill(Color.green)
                .onAnimationCompleted(
                    for: scale,
                    completion: scalingCompletion
                )
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
                        }
                    }
                    
                }
        }
        
        func scalingCompletion() {
            guard self.isAnimating else { return }

            self.executeAnimation(delay: false)
        }
        
        func executeAnimation(delay: Bool) {
//            print("executeAnimation")
            
            let duration = Double.random(in: 0.3...0.5)
//            print("duration: \(duration)")
            
            var animation = Animation
                .easeInOut(duration: duration)
            
            if delay {
                animation = animation
                    .delay(Double(self.index) * 0.1)
            }

            self.activeAnimation = animation
            

            withAnimation(self.activeAnimation) {
                if scale == self.maxScale {
                    self.scale = self.minScale
                }
                else {
                    self.scale = self.maxScale
                }
            }
        }
        
    }

}

/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserver<Content: View, Value: VectorArithmetic>: View, Animatable {

    let content: Content

    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var value: Value

    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void


    init(
        value: Value,
        completion: @escaping () -> Void,
        content: Content
    ) {
        self.animatableData = value
        self.value = value
        self.completion = completion
        self.content = content
    }
    
    var animatableData: Value {
        didSet {
            self.notifyCompletionIfFinished()
        }
    }
    
    var body: some View {
        content
    }

    private func notifyCompletionIfFinished() {

        if self.animatableData == self.value {
            DispatchQueue.main.async {
                self.completion()
            }
        }

    }

    

}

extension View {

    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(
        for value: Value,
        completion: @escaping () -> Void
    ) -> some View {
        return AnimationCompletionObserver(
            value: value,
            completion: completion,
            content: self
        )
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
