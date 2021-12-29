import Cocoa
import AppKit
import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts
import Logging

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static var shared: AppDelegate {
        NSApplication.shared.delegate as! AppDelegate
    }

    static let popoverWidth: CGFloat = 250
    static let popoverHeight: CGFloat = 460
    
    var settingsWindow: NSWindow? = nil

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu!
    
    // MARK: Environment Objects
    var spotify: Spotify!
    var playerManager: PlayerManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        SoftPlayerLogHandler.bootstrap()
        // spotifyDecodeLogger.logLevel = .trace
        // SwiftLogNoOpLogHandler.bootstrap()

        self.initializeKeyboardShortcutNames()

        self.configureContextMenu()

        self.spotify = Spotify()
        
        self.playerManager = PlayerManager(spotify: spotify)
        
        // MARK: Root View
        let rootView = RootView()
            .environmentObject(spotify)
            .environmentObject(playerManager)
            

        let popover = NSPopover()
        popover.contentSize = CGSize(
            width: Self.popoverWidth, height: Self.popoverHeight
        )
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self

        popover.contentViewController = NSHostingController(rootView: rootView)

        self.popover = popover

        self.statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = self.statusBarItem.button {
            // MARK: Menu Bar Icon Image
            let menuBarIcon = NSImage(.musicNoteCircle)

            menuBarIcon.size = CGSize(width: 18, height: 18)
            button.image = menuBarIcon
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
        }
        else {
            Loggers.general.critical(
                "AppDelegate.statusBarItem.button was nil"
            )
        }
        
    }
    
    func configureContextMenu() {
        
        self.contextMenu = NSMenu(
            title: NSLocalizedString("Options", comment: "")
        )
        self.contextMenu.addItem(
            withTitle: NSLocalizedString("Settings", comment: ""),
            action: #selector(self.openSettingsWindow),
            keyEquivalent: ""
        )
        self.contextMenu.addItem(
            withTitle: NSLocalizedString("Quit", comment: ""),
            action: #selector(NSApplication.shared.terminate(_:)),
            keyEquivalent: ""
        )
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.playerManager.spotifyApplication?.blockAppleEvents = true
        self.playerManager.playerStateDidChangeCancellable = nil
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        
        guard let url = urls.first else {
            Loggers.general.trace("application open urls: urls was empty")
            return
        }
        
        guard url.scheme == spotify.loginCallbackURL.scheme else {
            Loggers.general.trace("unsupported URL: \(url)")
            return
        }
        
        spotify.redirectURLSubject.send(url)
        
    }


    // MARK: - Manage Windows -

    @objc func openSettingsWindow() {
        
        self.closePopover()
        
        if self.settingsWindow == nil {
            
            let settingsView = SettingsView()
                .environmentObject(self.spotify)
                .environmentObject(self.playerManager)
            
            self.settingsWindow = NSWindow(
                contentRect: CGRect(x: 0, y: 0, width: 450, height: 400),
                styleMask: [
                    .titled,
                    .closable,
                    .miniaturizable,
                    .fullSizeContentView
                ],
                backing: .buffered,
                defer: false
            )
            
            self.settingsWindow?.center()
            self.settingsWindow?.setFrameAutosaveName("Settings")
            self.settingsWindow?.title = NSLocalizedString(
                "Settings", comment: ""
            )
            self.settingsWindow?.isReleasedWhenClosed = false
            self.settingsWindow?.contentView = NSHostingView(
                rootView: settingsView
            )
            
        }
        
        assert(
            self.settingsWindow != nil,
            "AppDelegate.settingsWindow was nil"
        )
        
        self.settingsWindow?.orderFrontRegardless()
        self.settingsWindow?.makeKey()
            
    }
    
    /// Global variables are lazily initialized, but this program relies on the
    /// keyboard shortcut names being initialized immediately.
    func initializeKeyboardShortcutNames() {
        typealias Name = KeyboardShortcuts.Name
        var sink = ""
        print(Name.showPlaylists, to: &sink)
        print(Name.previousTrack, to: &sink)
        print(Name.playPause, to: &sink)
        print(Name.nextTrack, to: &sink)
        print(Name.repeatMode, to: &sink)
        print(Name.shuffle, to: &sink)
        print(Name.volumeDown, to: &sink)
        print(Name.volumeUp, to: &sink)
        print(Name.onlyShowMyPlaylists, to: &sink)
        print(Name.settings, to: &sink)
        print(Name.quit, to: &sink)
    }

}

// MARK: - Popover -

extension AppDelegate: NSPopoverDelegate {
    
    @objc func togglePopover(_ sender: AnyObject?) {

        if let event = NSApplication.shared.currentEvent,
                event.type == .rightMouseDown {
            // then the user right-clicked on the status bar item

            self.statusBarItem.menu = self.contextMenu
            self.statusBarItem.button?.performClick(nil)
            self.statusBarItem.menu = nil

        }
        else {
            // assume the user left-clicked on the status bar item

            if self.popover.isShown {
                self.closePopover()
            }
            else {
                self.openPopover()
            }
            
        }

    }
    
    func openPopover() {
        
        guard let button = self.statusBarItem.button else {
            Loggers.general.critical(
                "AppDelegate.statusBarItem.button was nil"
            )
            return
        }

        self.popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: .minY
        )
        self.popover.contentViewController?.view.window?.becomeKey()
    }

    func closePopover() {
        self.popover.performClose(nil)
    }
    
    func popoverWillShow(_ notification: Notification) {
        self.playerManager.popoverWillShow.send()
    }

    func popoverDidClose(_ notification: Notification) {
        self.playerManager.popoverDidClose.send()
    }

}
