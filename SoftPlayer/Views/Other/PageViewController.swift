import SwiftUI
import AppKit

struct PageViewController<Page: View>: NSViewControllerRepresentable {
    
    let pages: [Page]
    
    @Binding var currentPage: Int
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeNSViewController(context: Context) -> NSPageController {
        let pageController = NSPageController()
        pageController.view = NSView()
        pageController.transitionStyle = .horizontalStrip
        pageController.delegate = context.coordinator
        //        pageController.arrangedObjects = context.coordinator.controllers
        pageController.arrangedObjects = context.coordinator.viewControllers
        
//        pageController.selectedIndex = self.currentPage
        pageController.animator().selectedIndex = self.currentPage
        
//        pageController.navigateForward(nil)
//        pageController.navigateBack(nil)
//        pageController.completeTransition()
//        pageController.selectedViewController =
//                context.coordinator.viewControllers[self.currentPage]
//
        return pageController
    }
    
    func updateNSViewController(_ pageController: NSPageController, context: Context) {
        print("updateNSViewController")
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
            
            let objectIdentifier = ObjectIdentifier(object as AnyObject)
            let identifier = String(describing: objectIdentifier)
//            print("identifier: \(identifier)")
            return identifier
            
        }
        
        func pageController(
            _ pageController: NSPageController,
            viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier
        ) -> NSViewController {
            
//            print("pageController: viewControllerForIdentifier: \(identifier)")
            
            for viewController in self.viewControllers {
                let objectIdentifier = ObjectIdentifier(viewController)
                if String(describing: objectIdentifier) == identifier {
                    return viewController
                }
            }

            fatalError(
                "could not create viewControllerForIdentifier \(identifier)"
            )
            
        }
        
        func pageController(
            _ pageController: NSPageController,
            prepare viewController: NSViewController,
            with object: Any?
        ) {
            
//            viewController.representedObject

//            print("pageController: prepare viewController: \(viewController)")
//            print("object: \(object ?? "nil")\n")
            
        }
        
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
            print("pageController.selectedIndex: \(pageController.selectedIndex)")
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
