import Foundation
import SwiftUI

struct PopupButton: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSPopUpButton {
        
        let menu = NSMenu()
        
        for i in 1...5 {
            let menuItem = NSMenuItem(
                title: "Option \(i)",
                action: nil,
                keyEquivalent: ""
            )
            menuItem.image = NSImage(.spotifyAlbumPlaceholder)
            menu.addItem(menuItem)
        }
//        menu.popUp(positioning: <#T##NSMenuItem?#>, at: <#T##NSPoint#>, in: <#T##NSView?#>)
        let popupButton = NSPopUpButton()
        popupButton.menu = menu
        return popupButton
        
    }
    
    func updateNSView(_ nsView: NSPopUpButton, context: Context) {
        
    }
    
    func displayMenu() {
        
    }
    
}
