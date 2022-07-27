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
        let searchField = CustomNSSearchField(
            parent: self
        )
        searchField.bezelStyle = .roundedBezel
        searchField.focusRingType = .none
        searchField.maximumNumberOfLines = 1
        searchField.delegate = context.coordinator
        return searchField
    }
    
    func updateNSView(_ searchField: CustomNSSearchField, context: Context) {
        
        searchField.stringValue = text

//        print("FocusableTextField.updateNSView: isFirstResponder: \(self.isFirstResponder)")

//        Loggers.keyEvent.info(
//            """
//            \(self.name): FocusableTextField.updateNSView: self.isFirstResponder: \
//            \(self.isFirstResponder); searchField.currentEditor() == nil: \
//            \(searchField.currentEditor() == nil)
//            searchField.stringValue: \(searchField.stringValue)
//            """
//        )

        self.updateFirstResponder(searchField)
        
    }
    
    func updateFirstResponder(_ searchField: CustomNSSearchField) {
        // If the `searchField` has a `currentEditor`, then it is the first
        // responder. Only make the search field the first responder if it is
        // not already the first responder.
        if self.isFirstResponder && searchField.currentEditor() == nil {
            /* && !context.coordinator.didMakeFirstResponder */
//            context.coordinator.didMakeFirstResponder = true
            let result = searchField.window?.makeFirstResponder(searchField)
            Loggers.firstResponder.trace(
                """
                \(self.name): CustomNSSearchField: made first responder: \
                \(String(describing: result))
                """
            )
            let range = NSRange(location: text.count, length: 0)
            searchField.currentEditor()?.selectedRange = range
        }
//        else if !self.isFirstResponder && searchField.currentEditor() != nil {
//            let result = searchField.window?.makeFirstResponder(nil)
//            Loggers.firstResponder.trace(
//                """
//                \(self.name): CustomNSSearchField: resigned responder: \
//                \(String(describing: result))
//                """
//            )
//        }
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
//            Loggers.keyEvent.trace(
//                "controlTextDidEndEditing: \(notification.userInfo as Any)"
//            )
            
            let textMovement = notification.userInfo?["NSTextMovement"] as? Int
            
            if textMovement == NSReturnTextMovement {
                self.parent.onCommit()
            }
            
        }
        
    }
}

class CustomNSSearchField: NSSearchField {

    let parent: FocusableTextField
    
    init(
        parent: FocusableTextField
    ) {
        self.parent = parent
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
//        print("CustomNSSearchField.performKeyEquivalent \(self.name!): ")
        return self.parent.receiveKeyEvent(event)
    }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        Loggers.firstResponder.trace(
            "\(self.parent.name): CustomNSSearchField: \(result)"
        )
        return result
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        Loggers.firstResponder.trace(
            "\(self.parent.name): CustomNSSearchField: \(result)"
        )
        return result
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        Loggers.firstResponder.trace(
            """
            \(self.parent.name): CustomNSSearchField: viewDidMoveToWindow; \
            window is nil: \(self.window == nil)
            """
        )
        self.parent.updateFirstResponder(self)
    }

}

//struct FocusableTextField2: NSViewControllerRepresentable {
//
//    @Binding var text: String
//    @Binding var isFirstResponder: Bool
//
//    let name: String
//    let onCommit: () -> Void
//    let receiveKeyEvent: (NSEvent) -> Bool
//
//    init(
//        name: String,
//        text: Binding<String>,
//        isFirstResponder: Binding<Bool>,
//        onCommit: @escaping () -> Void,
//        receiveKeyEvent: @escaping (NSEvent) -> Bool
//    ) {
//        self.name = name
//        self._text = text
//        self._isFirstResponder = isFirstResponder
//        self.onCommit = onCommit
//        self.receiveKeyEvent = receiveKeyEvent
//    }
//
//    func makeNSViewController(
//        context: Context
//    ) -> CustomNSSearchFieldViewController {
//        let viewController = CustomNSSearchFieldViewController()
//        viewController.swiftUIView = self
//        return viewController
//    }
//
//    func updateNSViewController(
//        _ viewController: CustomNSSearchFieldViewController,
//        context: Context
//    ) {
//
//        viewController.searchField.stringValue = text
//
////        print("FocusableTextField.updateNSView: isFirstResponder: \(self.isFirstResponder)")
//
////        Loggers.keyEvent.info(
////            """
////            \(self.name): FocusableTextField.updateNSView: self.isFirstResponder: \
////            \(self.isFirstResponder); searchField.currentEditor() == nil: \
////            \(searchField.currentEditor() == nil)
////            searchField.stringValue: \(searchField.stringValue)
////            """
////        )
//
//        // If the `searchField` has a `currentEditor`, then it is the first
//        // responder. Only make the search field the first responder if it is
//        // not already the first responder.
//        if self.isFirstResponder && viewController.searchField.currentEditor() == nil {
//            /* && !context.coordinator.didMakeFirstResponder */
////            context.coordinator.didMakeFirstResponder = true
//            let result = viewController.searchField.window?.makeFirstResponder(viewController.searchField)
//            Loggers.firstResponder.trace(
//                """
//                \(self.name): CustomNSSearchField: made first responder: \
//                \(String(describing: result))
//                """
//            )
//            let range = NSRange(location: text.count, length: 0)
//            viewController.searchField.currentEditor()?.selectedRange = range
//        }
////        else if !self.isFirstResponder && searchField.currentEditor() != nil {
////            let result = searchField.window?.makeFirstResponder(nil)
////            Loggers.firstResponder.trace(
////                """
////                \(self.name): CustomNSSearchField: resigned responder: \
////                \(String(describing: result))
////                """
////            )
////        }
//
//    }
//
//}
//
//class CustomNSSearchFieldViewController: NSViewController, NSSearchFieldDelegate {
//
//    var swiftUIView: FocusableTextField2!
//
//    var searchField: CustomNSSearchField {
//        get {
//            return self.view as! CustomNSSearchField
//        }
//        set {
//            self.view = newValue
//        }
//    }
//
//    override func loadView() {
//
//        let searchField = CustomNSSearchField()
//        searchField.translatesAutoresizingMaskIntoConstraints = false
//        searchField.bezelStyle = .roundedBezel
//        searchField.focusRingType = .none
//        searchField.maximumNumberOfLines = 1
//        searchField.delegate = self
//        searchField.receiveKeyEvent = self.swiftUIView.receiveKeyEvent
//        searchField.name = self.swiftUIView.name
//
//        self.view = searchField
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    override func viewDidAppear() {
//        Loggers.firstResponder.trace(
//            "\(self.swiftUIView.name): viewDidAppear"
//        )
//    }
//
//    func controlTextDidChange(_ notification: Notification) {
//        if let searchField = notification.object as? CustomNSSearchField {
//            self.swiftUIView.text = searchField.stringValue
//        }
//    }
//
//    func controlTextDidEndEditing(_ notification: Notification) {
//
//        guard notification.object is CustomNSSearchField else {
//            return
//        }
////            Loggers.keyEvent.trace(
////                "controlTextDidEndEditing: \(notification.userInfo as Any)"
////            )
//
//        let textMovement = notification.userInfo?["NSTextMovement"] as? Int
//
//        if textMovement == NSReturnTextMovement {
//            self.swiftUIView.onCommit()
//        }
//
//    }
//
//}
