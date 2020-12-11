import SwiftUI
import AppKit

// https://medium.com/fantageek/how-to-make-textfield-focus-in-swiftui-for-macos-d388c8f96103
struct FocusableTextField: NSViewRepresentable {
    
    @Binding var text: String
    @Binding var isFirstResponder: Bool

    let onCommit: () -> Void
    
    init(
        text: Binding<String>,
        isFirstResponder: Binding<Bool>,
        onCommit: @escaping () -> Void
    ) {
        self._text = text
        self._isFirstResponder = isFirstResponder
        self.onCommit = onCommit
    }
    
    func makeNSView(context: Context) -> NSSearchField {
        let searchField = NSSearchField()
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        searchField.maximumNumberOfLines = 1
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ searchField: NSSearchField, context: Context) {
        
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
            if let searchField = notification.object as? NSSearchField {
                parent.text = searchField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ notification: Notification) {
            print("controlTextDidEndEditing: \(notification.userInfo as Any)")
            
            
            if notification.object is NSSearchField,
               (notification.userInfo?["NSTextMovement"] as? Int) == NSReturnTextMovement {
                self.parent.onCommit()
            }
        }
        

    }
}
