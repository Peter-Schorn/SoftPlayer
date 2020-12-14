import SwiftUI
import AppKit

// https://medium.com/fantageek/how-to-make-textfield-focus-in-swiftui-for-macos-d388c8f96103
struct FocusableTextField: NSViewRepresentable {
    
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    let onCommit: () -> Void
    let receiveKeyEvent: (NSEvent) -> Bool
    
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        onCommit: @escaping () -> Void,
        receiveKeyEvent: @escaping (NSEvent) -> Bool
    ) {
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
        return searchField
    }
    
    func updateNSView(_ searchField: CustomNSSearchField, context: Context) {
        
        searchField.stringValue = text
        
        if self.isFirstResponder && !context.coordinator.didMakeFirstResponder {
            context.coordinator.didMakeFirstResponder = true
            searchField.window?.makeFirstResponder(searchField)
            let range = NSRange(location: text.count, length: 0)
            searchField.currentEditor()?.selectedRange = range
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, NSSearchFieldDelegate  {
        
        let parent: FocusableTextField
        var didMakeFirstResponder = false
        
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
//            print("controlTextDidEndEditing: \(notification.userInfo as Any)")
            
            let textMovement = notification.userInfo?["NSTextMovement"] as? Int
            
            if textMovement == NSReturnTextMovement {
                self.parent.onCommit()
            }
            else if [NSOtherTextMovement, NSCancelTextMovement]
                        .contains(textMovement) {
                self.parent.text = ""
            }
        }
        
    }
}

class CustomNSSearchField: NSSearchField {
 
    var receiveKeyEvent: ((NSEvent) -> Bool)? = nil
    
    override func keyDown(with event: NSEvent) {
        print("CustomNSSearchField: keyDown: \(event)")
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
       return receiveKeyEvent?(event) ?? false
    }
    
}
