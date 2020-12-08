import Foundation
import SwiftUI
import AppKit

class TouchBarPlaylistsViewController: NSViewController {

    override func loadView() {
        self.view = NSView()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.makeFirstResponder(self)

        // Do any additional setup after loading the view.
    }

}

extension TouchBarPlaylistsViewController: NSTouchBarDelegate {
    
    override func makeTouchBar() -> NSTouchBar? {
        
        print("makeTouchBar")
        
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .playlists
        touchBar.defaultItemIdentifiers = [.playlistsScrubber]
        touchBar.customizationAllowedItemIdentifiers = [.playlistsScrubber]
        return touchBar

    }
    
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        
        print("makeItemForIdentifier \(identifier)")
        
        guard identifier == .playlistsScrubber else { return nil }
        
        
        let scrubber = NSScrubber()

        scrubber.register(
            NSScrubberTextItemView.self,
            forItemIdentifier: .playlistsScrubberItem
        )

        scrubber.scrubberLayout = NSScrubberFlowLayout()
        scrubber.mode = .free
        scrubber.isContinuous = false
        scrubber.showsAdditionalContentIndicators = true
        scrubber.itemAlignment = .leading
        scrubber.selectionBackgroundStyle = .roundedBackground

        scrubber.delegate = self
        scrubber.dataSource = self

        let scrubberItem = NSCustomTouchBarItem(identifier: identifier)
        scrubberItem.view = scrubber

        return scrubberItem

    }

}

extension TouchBarPlaylistsViewController: NSScrubberDelegate {
    
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        print("selected at index \(index)")
    }

}

extension TouchBarPlaylistsViewController: NSScrubberDataSource {

    func numberOfItems(for scrubber: NSScrubber) -> Int {
//        print("number of items")
        return 40
    }

    func scrubber(
        _ scrubber: NSScrubber,
        viewForItemAt index: Int
    ) -> NSScrubberItemView {

//        print("scrubber viewForItemAt \(index)")

        let itemView = scrubber.makeItem(
            withIdentifier: .playlistsScrubberItem,
            owner: nil
        ) as! NSScrubberTextItemView

        itemView.title = "\(index)"
//        itemView.textField.stringValue = "Button \(index)"

        return itemView

    }

}

struct TouchBarPlaylistsView: NSViewControllerRepresentable {
    
    func makeNSViewController(
        context: Context
    ) -> TouchBarPlaylistsViewController {
        return TouchBarPlaylistsViewController()
    }
    
    func updateNSViewController(
        _ nsViewController: TouchBarPlaylistsViewController,
        context: Context
    ) {
        
    }

}
