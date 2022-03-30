import Foundation
import SwiftUI
import AppKit
import Combine

/// https://stackoverflow.com/a/61155272/12394554
struct KeyEventHandler: NSViewRepresentable {
    
    @Binding var isFirstResponder: Bool?

    let name: String
    let receiveKeyEvent: (NSEvent) -> Bool

    init(
        name: String = "",
        isFirstResponder: Binding<Bool?> = .constant(nil),
        receiveKeyEvent: @escaping (NSEvent) -> Bool
    ) {
        self.name = name
        self._isFirstResponder = isFirstResponder
        self.receiveKeyEvent = receiveKeyEvent
    }

    private class KeyHandlerView: NSView {
        
        let receiveKeyEvent: (NSEvent) -> Bool
        let name: String
       
        init(
            name: String,
            receiveKeyEvent: @escaping (NSEvent) -> Bool
        ) {
            self.name = name
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
        
        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            Loggers.keyEvent.trace(
                "\(self.name): becomeFirstResponder: \(result)"
            )
            return result
        }
        
        override func resignFirstResponder() -> Bool {
            let result = super.resignFirstResponder()
            Loggers.keyEvent.trace(
                "\(self.name): resignFirstResponder: \(result)"
            )
            return result
        }
        
    }
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlerView(
            name: self.name,
            receiveKeyEvent: self.receiveKeyEvent
        )
//        DispatchQueue.main.async {
            if self.isFirstResponder == true {
                if view.window?.firstResponder != view {
                    view.window?.makeFirstResponder(view)
                }
            }
//        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if self.isFirstResponder == true {
            if nsView.window?.firstResponder != nsView {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
        else if self.isFirstResponder == false {
            if nsView.window?.firstResponder == nsView {
                nsView.window?.makeFirstResponder(nil)
            }
        }
    }
    
}
