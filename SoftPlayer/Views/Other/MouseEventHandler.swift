import Foundation
import SwiftUI
import AppKit
import Combine

/// https://stackoverflow.com/a/61155272/12394554
struct MouseEventHandler: NSViewRepresentable {
    
    let mouseDown: (NSEvent) -> Void
    let mouseUp: (NSEvent) -> Void

    private class MouseHandlerView: NSView {
        
        let mouseDown: (NSEvent) -> Void
        let mouseUp: (NSEvent) -> Void

        init(
            mouseDown: @escaping (NSEvent) -> Void,
            mouseUp: @escaping (NSEvent) -> Void
        ) {
            self.mouseDown = mouseDown
            self.mouseUp = mouseUp
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func mouseDown(with event: NSEvent) {
            self.mouseDown(event)
        }
        
        override func mouseUp(with event: NSEvent) {
            self.mouseUp(event)
        }
        
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = MouseHandlerView(
            mouseDown: self.mouseDown,
            mouseUp: self.mouseUp
        )
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
}

extension View {
    
    @ViewBuilder func handleMouseEvents(
        mouseDown: @escaping (NSEvent) -> Void,
        mouseUp: @escaping (NSEvent) -> Void
    ) -> some View {
        
        let handler = MouseEventHandler(
            mouseDown: mouseDown,
            mouseUp: mouseUp
        )

        if #available(macOS 12.0, *) {
            self.overlay { handler }
        } else {
            self.overlay(handler)
        }

    }

}
