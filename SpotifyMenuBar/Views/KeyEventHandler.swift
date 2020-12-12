import Foundation
import SwiftUI
import AppKit
import Combine

/// https://stackoverflow.com/a/61155272/12394554
struct KeyEventHandler: NSViewRepresentable {
    
    let receiveKeyEvent: (NSEvent) -> Void
    
    private class KeyHandlerView: NSView {
        
        let receiveKeyEvent: (NSEvent) -> Void
       
        init(receiveKeyEvent: @escaping (NSEvent) -> Void) {
            self.receiveKeyEvent = receiveKeyEvent
            super.init(frame: NSZeroRect)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
//            print("keyDown: \(event.charactersIgnoringModifiers ?? "")")
            
            // key code 53 = escape key
            if event.charactersIgnoringModifiers != nil, event.keyCode != 53 {
                self.receiveKeyEvent(event)
            }
            else {
                super.keyDown(with: event)
            }
        }
    }
    
    func makeNSView(context: Context) -> NSView {
//        print("makeNSView")
        let view = KeyHandlerView(receiveKeyEvent: self.receiveKeyEvent)
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
}
