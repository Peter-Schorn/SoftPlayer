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
    
    func adaptiveShadow(
        radius: CGFloat,
        x: CGFloat = 0,
        y: CGFloat = 0
    ) -> some View {
        
        self.modifier(
            AdaptiveShadow(radius: radius, x: x, y: y)
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

struct AdaptiveShadow: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content.shadow(
            color: colorScheme == .dark ? .black : .defaultShadow,
            radius: radius,
            x: x,
            y: y
        )
    }
    
}

extension Color {
    
    /// The defult color for the `shadow` `View` modifier:
    /// `Color(.sRGBLinear, white: 0, opacity: 0.33)`.
    static let defaultShadow = Color(.sRGBLinear, white: 0, opacity: 0.33)

}
