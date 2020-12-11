import Combine
import SwiftUI

extension View {
    
    /// Returns `self` wrapped in `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

    @ViewBuilder func `if`<TrueContent: View>(
        _ condition: Bool,
        then trueContent: (Self) -> TrueContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            self
        }
    }

    @ViewBuilder func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueContent: (Self) -> TrueContent,
        else falseContent: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }
    
    func onKeyEvent(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.background(
            KeyEventHandler(receiveKeyEvent: action)
        )
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
