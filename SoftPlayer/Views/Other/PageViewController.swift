import SwiftUI
import AppKit

struct PageViewController<Page: View>: NSViewControllerRepresentable {
    
    let pages: [Page]
    
    @Binding var currentPage: Int
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSViewController(context: Context) -> NSPageController {
        
        print("--- makeNSViewController ---")

        let pageController = NSPageController()
        pageController.delegate = context.coordinator
        pageController.view = NSView()
        pageController.transitionStyle = .horizontalStrip
//        pageController.selectedViewController =
//                context.coordinator.viewControllers[self.currentPage]
        
//        pageController.arrangedObjects = context.coordinator.viewControllers
        pageController.arrangedObjects = Array(self.pages.indices)
        
//        pageController.animator().selectedIndex = self.currentPage
        
        

        if self.currentPage == 0 {
            pageController.selectedIndex = 1
            pageController.navigateBack(nil)
        }
        else if self.currentPage == 1 {
            pageController.selectedIndex = 0
            pageController.navigateForward(nil)
        }
        else {
            fatalError("unreachable")
        }
        
        return pageController
        
    }
    
    func updateNSViewController(_ pageController: NSPageController, context: Context) {
        
//        print("updateNSViewController")
        
        if pageController.selectedIndex != self.currentPage {
            DispatchQueue.main.async {
                pageController.animator().selectedIndex = self.currentPage
            }
        }
        
    }
    
    class Coordinator: NSObject, NSPageControllerDelegate {
        
        let parent: PageViewController
        let viewControllers: [NSViewController]
        
        init(_ pageController: PageViewController) {
            self.parent = pageController
            self.viewControllers = parent.pages.map {
                NSHostingController(rootView: $0)
            }
        }
        
        func pageController(
            _ pageController: NSPageController,
            identifierFor object: Any
            // typealias ObjectIdentifier = String
        ) -> NSPageController.ObjectIdentifier {
            
//            print("pageController: identifierFor: \(object)")
            
//            let objectIdentifier = ObjectIdentifier(object as AnyObject)
//            let identifier = String(describing: objectIdentifier)
////            print("identifier: \(identifier)")
//            return identifier
            
            return String(describing: object)
            
        }
        
        func pageController(
            _ pageController: NSPageController,
            viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier
        ) -> NSViewController {
            
//            print("pageController: viewControllerForIdentifier: \(identifier)")
            
            let index = Int(identifier)!

            return self.viewControllers[index]
            

//            for viewController in self.viewControllers {
//                let objectIdentifier = ObjectIdentifier(viewController)
//                if String(describing: objectIdentifier) == identifier {
//                    return viewController
//                }
//            }

//            fatalError(
//                "could not create viewControllerForIdentifier \(identifier)"
//            )
            
        }
        
//        func pageController(
//            _ pageController: NSPageController,
//            prepare viewController: NSViewController,
//            with object: Any?
//        ) {
//
////            viewController.representedObject
//
////            print("pageController: prepare viewController: \(viewController)")
////            print("object: \(object ?? "nil")\n")
//
//        }
        
        func pageControllerWillStartLiveTransition(
            _ pageController: NSPageController
        ) {
//            print("pageControllerWillStartLiveTransition")
//            print("pageController.selectedIndex: \(pageController.selectedIndex)")
        }
        
        func pageController(
            _ pageController: NSPageController,
            didTransitionTo object: Any
        ) {
            
            DispatchQueue.main.async {
                self.parent.currentPage = pageController.selectedIndex
            }
//            print("pageController: didTransitionTo \(object)")
//            print("pageController.selectedIndex: \(pageController.selectedIndex)")
        }
        
        func pageControllerDidEndLiveTransition(
            _ pageController: NSPageController
        ) {
//            print("pageControllerDidEndLiveTransition")
//            print("pageController.selectedIndex: \(pageController.selectedIndex)")
            pageController.completeTransition()
//            print("pageController.selectedIndex: \(pageController.selectedIndex)")
        }
        
    }
    
}

class CustomPageController: NSPageController {
    
    override func loadView() {
        self.view = NSView()
    }
    
    var _selectedViewController: NSViewController?

    override var selectedViewController: NSViewController? {
        get {
            return self._selectedViewController
        }
        set {
            self._selectedViewController = newValue
        }
    }


}
