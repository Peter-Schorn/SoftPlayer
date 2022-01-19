import SwiftUI
import AppKit

// https://medium.com/fantageek/how-to-make-textfield-focus-in-swiftui-for-macos-d388c8f96103
struct FocusableTextField: NSViewRepresentable {
    
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    let name: String
    let onCommit: () -> Void
    let receiveKeyEvent: (NSEvent) -> Bool
    
    init(
        name: String,
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        onCommit: @escaping () -> Void,
        receiveKeyEvent: @escaping (NSEvent) -> Bool
    ) {
        self.name = name
        self._text = text
        self._isFirstResponder = isFirstResponder
        self.onCommit = onCommit
        self.receiveKeyEvent = receiveKeyEvent
    }
    
    func makeNSView(context: Context) -> CustomNSSearchField {
        let searchField = CustomNSSearchField()
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        searchField.maximumNumberOfLines = 1
        searchField.delegate = context.coordinator
        searchField.receiveKeyEvent = self.receiveKeyEvent
        searchField.name = self.name
        return searchField
    }
    
    func updateNSView(_ searchField: CustomNSSearchField, context: Context) {
        
        searchField.stringValue = text
        
        Loggers.keyEvent.info(
            """
            \(self.name): FocusableTextField.updateNSView: self.isFirstResponder: \
            \(self.isFirstResponder); searchField.currentEditor() == nil: \
            \(searchField.currentEditor() == nil)
            searchField.stringValue: \(searchField.stringValue)
            """
        )

        // If the `searchField` has a `currentEditor`, then it is the first
        // responder. Only make the search field the first responder if it is
        // not already the first responder.
        if self.isFirstResponder /* && searchField.currentEditor() == nil */ {
            /* && !context.coordinator.didMakeFirstResponder */
//            context.coordinator.didMakeFirstResponder = true
            searchField.window?.makeFirstResponder(searchField)
            Loggers.keyEvent.info("\(self.name): made first responder")
            let range = NSRange(location: text.count, length: 0)
            searchField.currentEditor()?.selectedRange = range
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate  {
        
        let parent: FocusableTextField
//        var didMakeFirstResponder = false
        
        init(parent: FocusableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ notification: Notification) {
            if let searchField = notification.object as? CustomNSSearchField {
                parent.text = searchField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ notification: Notification) {

            guard notification.object is CustomNSSearchField else {
                return
            }
            Loggers.keyEvent.trace(
                "controlTextDidEndEditing: \(notification.userInfo as Any)"
            )
            
            let textMovement = notification.userInfo?["NSTextMovement"] as? Int
            
            if textMovement == NSReturnTextMovement {
                self.parent.onCommit()
            }
            
        }
        
    }
}

class CustomNSSearchField: NSSearchField {

    var name: String!

    var receiveKeyEvent: ((NSEvent) -> Bool)? = nil
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
//        print("CustomNSSearchField.performKeyEquivalent \(self.name!): ")
        return receiveKeyEvent?(event) ?? false
    }
    
    override func becomeFirstResponder() -> Bool {
//        Loggers.keyEvent.info(
//            "\(self.name!): CustomNSSearchField.becomeFirstResponder"
//        )
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
//        Loggers.keyEvent.info(
//            "\(self.name!): CustomNSSearchField.resignFirstResponder"
//        )
        return super.resignFirstResponder()
    }

}
