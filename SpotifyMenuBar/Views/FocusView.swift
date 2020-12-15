import SwiftUI
import AppKit

// https://stackoverflow.com/a/62142439/12394554

class FocusNSView: NSView {
    override var acceptsFirstResponder: Bool {
        return true
    }
}

/// Gets the keyboard focus if nothing else is focused.
struct FocusView: NSViewRepresentable {

    @Binding var isFirstResponder: Bool
    
    func makeNSView(context: NSViewRepresentableContext<FocusView>) -> FocusNSView {
        return FocusNSView()
    }

    func updateNSView(_ nsView: FocusNSView, context: Context) {

        // Delay making the view the first responder to avoid SwiftUI errors.
        if self.isFirstResponder {
//            print("FocusView: makeFirstResponder")
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
        else {
//            print("FocusView: resignFirstResponder")
            nsView.window?.makeFirstResponder(nil)
        }
    }
    
    

}
