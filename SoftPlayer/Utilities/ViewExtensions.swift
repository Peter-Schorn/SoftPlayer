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
        
        if #available(macOS 12.0, *) {
            self.overlay(alignment: alignment, content: content)
        } else {
            self.overlay(content(), alignment: alignment)
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
