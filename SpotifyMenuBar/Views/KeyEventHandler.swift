import Foundation
import SwiftUI
import AppKit
import Combine

/// https://stackoverflow.com/a/61155272/12394554
struct KeyEventHandler: NSViewRepresentable {
    
    let receiveKeyEvent: (NSEvent) -> Bool
    
    private class KeyHandlerView: NSView {
        
        let receiveKeyEvent: (NSEvent) -> Bool
       
        init(receiveKeyEvent: @escaping (NSEvent) -> Bool) {
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
            if event.keyCode != 53 {
                if !self.receiveKeyEvent(event) {
                    super.keyDown(with: event)
                }
            }
            else {
                super.keyDown(with: event)
            }
        }
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerView(receiveKeyEvent: self.receiveKeyEvent)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
}
