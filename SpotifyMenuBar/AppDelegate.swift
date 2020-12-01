import Cocoa
import AppKit
import SwiftUI
import SpotifyWebAPI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let popoverWidth = 250
    static let popoverHeight = 470
    
//    var window: NSWindow!
    
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    
    // MARK: Environment Objects
    var spotify: Spotify!
    var playerManager: PlayerManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        self.spotify = Spotify()
        
        // MARK: DEBUG
//        self.spotify.api.authorizationManager.deauthorize()
        
        self.playerManager = PlayerManager(spotify: spotify)
        
        SpotifyAPILogHandler.bootstrap()
        
        let rootView = RootView()
            .environment(\.managedObjectContext, persistentContainer.viewContext)
            .environmentObject(spotify)
            .environmentObject(playerManager)

        let popover = NSPopover()
        popover.contentSize = NSSize(
            width: Self.popoverWidth, height: Self.popoverHeight
        )
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.animates = false
        self.popover = popover

        self.statusBarItem = NSStatusBar.system.statusItem(
            withLength: CGFloat(NSStatusItem.variableLength)
        )
        if let button = self.statusBarItem.button {
             button.image = NSImage(named: "music.note")
             button.action = #selector(togglePopover(_:))
        }
        
//        self.window = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 210, height: 400),
//            styleMask: [
//                .titled,
//                .closable,
//                .miniaturizable,
//                .fullSizeContentView
//            ],
//            backing: .buffered, defer: false)
//        window.center()
//        window.setFrameAutosaveName("Main Window")
//        window.title = "Reddit"
//
//        window.contentView = NSHostingView(rootView: rootView)
//        window.makeKeyAndOrderFront(nil)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            } else {
                self.playerManager.popoverDidShow.send()
                self.popover.show(
                    relativeTo: button.bounds,
                    of: button,
                    preferredEdge: NSRectEdge.minY
                )
                self.popover.contentViewController?.view.window?.becomeKey()

            }
        }
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        
        guard let url = urls.first else {
            print("application open urls: urls was empty")
            return
        }
        
        guard url.scheme == spotify.loginCallbackURL.scheme else {
            print("unsupported URL:", url)
            return
        }
        
        spotify.redirectURLSubject.send(url)
        
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "SpotifyMenuBar")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error
                // appropriately.
                // fatalError() causes the application to generate a crash log
                // and terminate. You should not use this function in a shipping
                // application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or
                   disallows writing.
                 * The persistent store is not accessible, due to permissions or
                   data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save:
        // message to the application's managed object context. Any encountered errors
        // are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            let classString = NSStringFromClass(type(of: self))
            NSLog("\(classString) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific
                // recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager
        // returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the
        // application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            let classString = NSStringFromClass(type(of: self))
            NSLog("\(classString) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific
            // recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString(
                "Could not save changes while quitting. Quit anyway?",
                comment: "Quit without saves error question message"
            )
            let info = NSLocalizedString(
                "Quitting now will lose any changes you have made since the last " +
                "successful save",
                comment: "Quit without saves error question info"
            )
            let quitButton = NSLocalizedString(
                "Quit anyway",
                comment: "Quit anyway button title"
            )
            let cancelButton = NSLocalizedString(
                "Cancel", comment: "Cancel button title"
            )
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}

