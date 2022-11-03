import Combine
import SwiftUI
import AppKit

extension View {
    
    /// Returns `self` wrapped in `AnyView`. Equivalent to `AnyView(self)`.
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

    @ViewBuilder func `if`<TrueContent: View>(
        _ condition: Bool,
        @ViewBuilder then trueContent: (Self) -> TrueContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            self
        }
    }

    @ViewBuilder func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder then trueContent: (Self) -> TrueContent,
        @ViewBuilder else falseContent: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }
    
    @ViewBuilder func ifLet<T, Content: View>(
        _ t: T?, @ViewBuilder _ content: (Self, T) -> Content
    ) -> some View {
        if let t = t {
            content(self, t)
        }
        else {
            self
        }
    }

    func modify<Content: View>(
        @ViewBuilder _ content: (Self) -> Content
    ) -> some View {
        content(self)
    }
    
    @ViewBuilder func versionedBackground<V>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> V
    ) -> some View where V : View {
        
        if #available(macOS 12.0, *) {
            self.background(alignment: alignment, content: content)
        } else {
            self.background(content(), alignment: alignment)
        }

    }
    
    @ViewBuilder func versionedOverlay<V>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> V
    ) -> some View where V : View {
        
        #if compiler(<5.4)
        self.overlay(content(), alignment: alignment)
        #else
        if #available(macOS 12.0, *) {
            self.overlay(alignment: alignment, content: content)
        } else {
            self.overlay(content(), alignment: alignment)
        }
        #endif
        

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

    func tapAndLongPressAndHoldGesture(
        _ state: GestureState<TapAndLongPressGestureState>,
        onTap: @escaping () -> Void
    ) -> some View {
        self.gesture(
            TapGesture()
                .simultaneously(
                    with: LongPressGesture(minimumDuration: .infinity)
                )
                .updating(state) { value, state, transaction in
//                    print(
//                        """
//                        updating:
//                            value:
//                                TapGesture: \(value.first as Any)
//                                LongPressGesture: \(value.second as Any)
//                            state: \(state)
//
//                        """
//                    )
                    
                    state.isTapping = value.first != nil
//                    print("--- state.isTapping = \(state.isTapping) ---")

                    if value.first == nil {
                        state.isLongPressing = value.second ?? false
                    }
                    
                }
                .onEnded { value in
//                    print(
//                        """
//                        onEnded:
//                            value:
//                                TapGesture: \(value.first as Any)
//                                LongPressGesture: \(value.second as Any)
//
//                        """
//                    )
                    onTap()
                }
                
        )
    }
    
    @ViewBuilder func customDisabled(_ disabled: Bool) -> some View {
        if disabled {
            self
                .foregroundColor(.secondary)
                .allowsHitTesting(false)
        }
        else {
            self
        }
    }
    
    @ViewBuilder func onDragOptional(
        _ data: @escaping () -> NSItemProvider?
    ) -> some View {
        if let provider = data() {
            self.onDrag({ provider })
        }
        else {
            self
        }
    }

    @ViewBuilder func onDragOptional<V: View>(
        _ data: @escaping () -> NSItemProvider?,
        @ViewBuilder preview: () -> V
    ) -> some View {
        if let provider = data() {
            if #available(macOS 12.0, *) {
                self.onDrag({ provider }, preview: preview)
            } else {
                self.onDrag({ provider })
            }
        }
        else {
            self
        }
    }
    
    
    /**
     Adds an action to perform when the user moves the pointer over or away from
     the view’s frame, after applying the specified delays.
     
     - Parameters:
       - enterDelay: The number of seconds for which the pointer must be
             continously in the frame before `action` is called with a value of
             `true` passed in. The default is half a second. If the pointer
             enters the frame for a period of time less than the delay and then
             leaves it again, the timer is reset.
       - exitDelay: The number of seconds for which the pointer must be
             continously *outside* the frame before `action` is called with a
             value of `false` passed in. If `nil`, then `exitDelay` will be the
             same as `enterDelay`. The default is `nil`. If the pointer leaves
             the frame for a period of time less than the delay and then enters
             it again, the timer is reset.
       - action: The action to perform whenever the pointer enters or exits
             this view’s frame. If the pointer is in the view’s frame, the
             action closure passes true as a parameter; otherwise, false. The
             closure will be called on the main thread.
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

struct TapAndLongPressGestureState: Hashable {

    var isTapping = false
    var isLongPressing = false
    
    init() {
        
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
    
    /// The default color for the `shadow` `View` modifier:
    /// `Color(.sRGBLinear, white: 0, opacity: 0.33)`.
    static let defaultShadow = Color(.sRGBLinear, white: 0, opacity: 0.33)
    
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(
            .sRGB,
            red: red,
            green: green,
            blue: blue,
            opacity: opacity
        )
    }


}

extension PreviewProvider {
    
    static func withAllColorSchemes<Content: View>(
        previewDisplayName: String? = nil,
        @ViewBuilder _ content: @escaping () -> Content
    ) -> some View {
        
        let prefix = previewDisplayName.map { "\($0) - " } ?? ""
        
        return ForEach(ColorScheme.allCases, id: \.self) { colorScheme in
            content()
                .preferredColorScheme(colorScheme)
                .previewDisplayName(
                    "\(prefix)\(colorScheme)"
                )
        }
        
    }
    
}
