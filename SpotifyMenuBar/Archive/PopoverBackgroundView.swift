import Foundation
import AppKit
import Combine

class PopoverContentView: NSView {
    
    var backgroundView: PopoverBackgroundView? = nil

    let playerManager: PlayerManager
    
    init(playerManager: PlayerManager) {
        self.playerManager = playerManager
        super.init(frame: NSRect())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let frameView = self.window?.contentView?.superview,
                backgroundView == nil {
            backgroundView = PopoverBackgroundView(
                frame: frameView.bounds, playerManager: playerManager
            )
            backgroundView!.autoresizingMask = NSView.AutoresizingMask(
                [.width, .height]
            )
            frameView.addSubview(
                backgroundView!,
                positioned: NSWindow.OrderingMode.below,
                relativeTo: frameView
            )
        }
    }
}

class PopoverBackgroundView: NSView {
    
    let playerManager: PlayerManager
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(frame: NSRect, playerManager: PlayerManager) {
        self.playerManager = playerManager
        super.init(frame: frame)
        self.frame = frame
        
//        self.playerManager.$nsArtworkImage.sink { _ in
//            print("\nSET NEEDS DISPLAY\n")
//            self.setNeedsDisplay(self.frame)
//        }
//        .store(in: &cancellables)

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
//        print("drawing popover background view")
//        let color = playerManager.nsArtworkImage?.averageColor
//        self.layer?.backgroundColor = color?.cgColor
    }
    
}
