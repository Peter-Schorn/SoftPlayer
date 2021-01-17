import Foundation
import SwiftUI
import Combine

struct DelayedHover: ViewModifier {
    
    @State private var cancellable: AnyCancellable? = nil
    @State private var lastValue: Bool? = nil

    let enterDelay: Double
    let exitDelay: Double
    let onHover: (_ isHovering: Bool) -> Void

    func body(content: Content) -> some View {
        content.onHover { isHovering in
//            print("HoveringDelay isHovering: \(isHovering)")
            let delay = isHovering ? enterDelay : exitDelay
            self.cancellable = Just(isHovering)
                .delay(for: .seconds(delay), scheduler: RunLoop.main)
                .sink { isHovering in
                    if self.lastValue != isHovering {
                        self.onHover(isHovering)
                    }
                    self.lastValue = isHovering
                }
        }
    }

}

extension View {
    
    /**
     Adds an action to perform when the user moves the pointer over
     or away from the view’s frame, after applying the specified delays.
     
     - Parameters:
       - enterDelay: The number of seconds for which the pointer must be
             in the frame before `action` is called with a value of `true`
             passed in. The default is half a second.
       - exitDelay: The number of seconds for which the pointer must be
             *outside* the frame before `action` is called with a value of
             `false` passed in. If `nil`, then `exitDelay` will be the same
             as `enterDelay`. The default is `nil`.
       - action: The action to perform whenever the pointer enters or exits
             this view’s frame. If the pointer is in the view’s frame, the
             action closure passes true as a parameter; otherwise, false.
     */
    func onHover(
        enterDelay: Double = 0.5,
        exitDelay: Double? = nil,
        action: @escaping (_ isHovering: Bool) -> Void
    ) -> some View {
        
        self.modifier(
            DelayedHover(
                enterDelay: enterDelay,
                // By default, make the exit delay the same as
                // the enter delay.
                exitDelay: exitDelay ?? enterDelay,
                onHover: action
            )
        )

    }

}
