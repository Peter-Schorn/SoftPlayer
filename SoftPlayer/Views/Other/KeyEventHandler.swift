import Foundation
import SwiftUI
import AppKit
import Combine

/// https://stackoverflow.com/a/61155272/12394554
struct KeyEventHandler: NSViewRepresentable {
    
    @Binding var isFirstResponder: Bool?

    let receiveKeyEvent: (NSEvent) -> Bool
    
    init(
        isFirstResponder: Binding<Bool?> = .constant(nil),
        receiveKeyEvent: @escaping (NSEvent) -> Bool
    ) {
        self._isFirstResponder = isFirstResponder
        self.receiveKeyEvent = receiveKeyEvent
    }

    private class KeyHandlerView: NSView {
        
        let receiveKeyEvent: (NSEvent) -> Bool
       
        init(receiveKeyEvent: @escaping (NSEvent) -> Bool) {
            self.receiveKeyEvent = receiveKeyEvent
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
//            Loggers.keyEvent.trace(
//                "keyDown: \(event.charactersIgnoringModifiers ?? "")"
//            )
            
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
            if self.isFirstResponder == true {
                if view.window?.firstResponder != view {
                    view.window?.makeFirstResponder(view)
                }
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if self.isFirstResponder == true {
            if nsView.window?.firstResponder != nsView {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
        else if self.isFirstResponder == false {
            nsView.window?.makeFirstResponder(nil)
        }
    }
    
}
