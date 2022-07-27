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

    class KeyHandlerView: NSView {
        
        let parent: KeyEventHandler
       
        init(
            parent: KeyEventHandler
        ) {
            self.parent = parent
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
                if !self.parent.receiveKeyEvent(event) {
                    super.keyDown(with: event)
                }
            }
            else {
                super.keyDown(with: event)
            }
        }
        
        override func becomeFirstResponder() -> Bool {
            let result = super.becomeFirstResponder()
            Loggers.firstResponder.trace(
                "\(self.parent.name): KeyEventHandler: \(result)"
            )
            return result
        }
        
        override func resignFirstResponder() -> Bool {
            let result = super.resignFirstResponder()
            Loggers.firstResponder.trace(
                "\(self.parent.name): KeyEventHandler: \(result)"
            )
            return result
        }
        
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            Loggers.firstResponder.trace(
                """
                \(self.parent.name): KeyEventHandler: viewDidMoveToWindow; \
                window is nil: \(self.window == nil)
                """
            )
            self.parent.updateFirstResponder(self)
        }
        
    }
    
    func makeNSView(context: Context) -> KeyHandlerView {
        let keyHandlerView = KeyHandlerView(
            parent: self
        )
//        DispatchQueue.main.async {
//            if self.isFirstResponder == true {
//                if view.window?.firstResponder != view {
//                    view.window?.makeFirstResponder(view)
//                }
//            }
//        }
        return keyHandlerView
    }
    
    func updateNSView(_ keyHandlerView: KeyHandlerView, context: Context) {
        self.updateFirstResponder(keyHandlerView)
    }
    
    func updateFirstResponder(_ keyHandlerView: KeyHandlerView) {
        
        let iskeyFirstResponder: Bool
        if let window = keyHandlerView.window,
                window.firstResponder == keyHandlerView,
               window.isKeyWindow {
            iskeyFirstResponder = true
        }
        else {
            iskeyFirstResponder = false
        }

        Loggers.firstResponder.trace(
            """
            \(self.name): KeyEventHandler: might update first responder; \
            iskeyFirstResponder: \(iskeyFirstResponder); \
            @Binding isFirstResponder: \(String(describing: self.isFirstResponder)); \
            NSView is first responder: \(keyHandlerView.window?.firstResponder == keyHandlerView)
            """
        )
        
        if self.isFirstResponder == true {
            if keyHandlerView.window?.firstResponder != keyHandlerView {
                let result = keyHandlerView.window?.makeFirstResponder(keyHandlerView)
                Loggers.firstResponder.trace(
                    """
                    \(self.name): KeyEventHandler: made first responder: \
                    \(String(describing: result))
                    """
                )
            }
        }
//        else if self.isFirstResponder == false {
//            if nsView.window?.firstResponder == nsView {
//                let result = nsView.window?.makeFirstResponder(nil)
//                Loggers.firstResponder.trace(
//                    """
//                    \(self.name): KeyEventHandler: resigned first responder: \
//                    \(String(describing: result))
//                    """
//                )
//            }
//        }
    }
    
}

extension NSView {
    
    var isFirstResponder: Bool {
        return self.window?.firstResponder == self &&
                self.window?.isKeyWindow == true
    }

}
