import Foundation
import SwiftUI

struct AppKitMenu<Label: View>: NSViewControllerRepresentable {
    
    @Binding var isOpen: Bool

    let label: Label
    let items: [MenuItem]
    
    init(isOpen: Binding<Bool>, label: Label, items: [MenuItem]) {
        self._isOpen = isOpen
        self.label = label
        self.items = items
        let names = self.items.map(\.title)
        print("---\n\nAppKitMenu.init: \(names)\n\n---")
    }
    
    func makeNSViewController(context: Context) -> ViewController {
        print("makeNSViewController")
        
        let viewController = ViewController()
        viewController.configure(appKitMenu: self)
        return viewController
        
    }

    func updateNSViewController(
        _ nsViewController: ViewController, context: Context
    ) {
        print(
            """
            updateNSViewController isOpen: \(self.isOpen)
            """
        )
        
        nsViewController.appKitMenu = self
        nsViewController.reloadMenuItems()
        
        
        if self.isOpen {
            nsViewController.popupMenu()
        }
        else {
            nsViewController.closeMenu()
        }
        
    }

    class ViewController: NSViewController, NSMenuDelegate {

        var appKitMenu: AppKitMenu!

        var customMenu: NSMenu!
        
        func configure(appKitMenu: AppKitMenu) {
//            print("ViewController.configure: \()")
            self.appKitMenu = appKitMenu
            
            self.view = NSHostingView(rootView: self.appKitMenu.label)
            self.view.translatesAutoresizingMaskIntoConstraints = false
            self.customMenu = NSMenu()
            self.customMenu.delegate = self
            
            self.reloadMenuItems()
        }
        
        func reloadMenuItems() {
            self.customMenu.items = self.appKitMenu.items.map(\.nsMenuItem)
            let customMenuTitles = self.customMenu.items.map(\.title)
            let appKitMenTitles = self.appKitMenu.items.map(\.title)
            print(
                """
                reloadMenuItems
                customMenu: \(customMenuTitles)
                appKitMenu: \(appKitMenTitles)
                """
            )
        }

        func popupMenu() {
            
            print(
                """
                outside before queue will popup menu \
                appKitMenu.isOpen: \(self.appKitMenu.isOpen)
                """
            )
            DispatchQueue.main.async {
                print("inside queue will popup menu")
                guard self.appKitMenu.isOpen else {
                    print("appKitMenu.isOpen == false; not opening")
                    return
                }
                
                let bottomLeft = NSPoint(
                    x: self.view.frame.minX,
                    y: self.view.frame.maxY + 5
                )
                
                self.customMenu.popUp(
                    positioning: self.customMenu.items.first,
                    at: bottomLeft,
                    in: self.view
                )
            }
            
        }


        func closeMenu() {
            
            self.customMenu.cancelTracking()
        }

        func menuWillOpen(_ menu: NSMenu) {
//            print("menuWillOpen")
        }

        
        func menuDidClose(_ menu: NSMenu) {
//            print("menuDidClose")
            self.appKitMenu.isOpen = false
        }

    }

}

class MenuItem {

    let title: String
    let state: NSControl.StateValue
    let action: () -> Void

    let nsMenuItem: NSMenuItem

    init(
        title: String,
        state: NSControl.StateValue = .off,
        action: @escaping () -> Void,
        enabled: Bool = true
    ) {
        self.title = title
        self.state = state
        self.action = action
        
        self.nsMenuItem = NSMenuItem(
            title: self.title,
            action: #selector(objcAction),
            keyEquivalent: ""
        )
        self.nsMenuItem.state = self.state
        if enabled {
            self.nsMenuItem.target = self
        }

    }
    
    @objc func objcAction() {
        self.action()
    }


}
