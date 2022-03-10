import Foundation
import SwiftUI
import AppKit
import Combine

struct MouseEventHandler: NSViewRepresentable {
    
    let mouseDown: (NSView, NSEvent) -> Void
    let mouseUp: (NSView, NSEvent) -> Void

    private class MouseHandlerView: NSView {
        
        let mouseDown: (NSView, NSEvent) -> Void
        let mouseUp: (NSView, NSEvent) -> Void

        init(
            mouseDown: @escaping (NSView, NSEvent) -> Void,
            mouseUp: @escaping (NSView, NSEvent) -> Void
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
            self.mouseDown(self, event)
        }
        
        override func mouseUp(with event: NSEvent) {
            self.mouseUp(self, event)
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
        mouseDown: @escaping (NSView, NSEvent) -> Void,
        mouseUp: @escaping (NSView, NSEvent) -> Void
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
