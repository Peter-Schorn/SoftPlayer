import Combine
import SwiftUI

extension View {
    
    /// Returns `self` wrapped in `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

    /**
     A gesture that recognizs a tap and a long press.
     
     - Parameters:
       - onTap: Called in response to a tap gesture.
       - isLongPressing: Updated based on whether the user is currently
             long-pressing on a view.
     */
    func tapAndLongPressAndHoldGesture(
        onTap: @escaping () -> Void, isLongPressing: GestureState<Bool>
    ) -> some View {
        return self.gesture(
            TapGesture()
                .onEnded { _ in onTap() }
                .exclusively(before: LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: LongPressGesture(minimumDuration: .infinity))
                    .updating(isLongPressing) { value, state, transaction in
                        if case .second(true, nil) = value {
                            state = true
                        }
                    }
                )
        )
    }

}
