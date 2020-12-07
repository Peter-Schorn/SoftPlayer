import Foundation
import SwiftUI
import AppKit

struct TouchBarPlaylistsView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSView {
        return NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        
    }
    
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        
        let scrubberItem: NSCustomTouchBarItem
        
        scrubberItem = NSCustomTouchBarItem(identifier: identifier)
        scrubberItem.customizationLabel = NSLocalizedString(
            "Choose Photo", comment: ""
        )
        
        let scrubber = NSScrubber()
        scrubber.register(
            NSScrubberImageItemView.self,
            forItemIdentifier: .init(rawValue: "")
        )
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .roundedBackground
        //            scrubber.delegate = self
        //            scrubber.dataSource = self
        scrubber.showsAdditionalContentIndicators = true
        scrubber.scrubberLayout = NSScrubberFlowLayout()
        
        scrubberItem.view = scrubber
        
        // Set the scrubber's width to be 400.
        let viewBindings: [String: NSView] = ["scrubber": scrubber]
        
        let hconstraints = NSLayoutConstraint.constraints(
            withVisualFormat: "H:[scrubber(400)]",
            options: [],
            metrics: nil,
            views: viewBindings
        )
        NSLayoutConstraint.activate(hconstraints)
        
        return scrubberItem
    }
    
}
