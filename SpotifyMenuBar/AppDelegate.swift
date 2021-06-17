import Cocoa
import AppKit
import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static let popoverWidth: CGFloat = 250
    static let popoverHeight: CGFloat = 460
    
    var settingsWindow: NSWindow? = nil
    
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    
    // MARK: Environment Objects
    var spotify: Spotify!
    var playerManager: PlayerManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        SpotifyMenuBarLogHandler.bootstrap()

        self.initializeKeyboardShortcutNames()

        self.spotify = Spotify()
        
        self.playerManager = PlayerManager(spotify: spotify)
        
        let rootView = RootView()
            .environmentObject(spotify)
            .environmentObject(playerManager)

        let popover = NSPopover()
        popover.contentSize = NSSize(
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
             button.image = NSImage(named: "music.note")
             button.action = #selector(togglePopover(_:))
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = self.statusBarItem.button {
            if self.popover.isShown {
                self.popover.performClose(sender)
            }
            else {
                self.playerManager.popoverWillShow.send()
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
            Loggers.general.trace("application open urls: urls was empty")
            return
        }
        
        guard url.scheme == spotify.loginCallbackURL.scheme else {
            Loggers.general.trace("unsupported URL: \(url)")
            return
        }
        
        spotify.redirectURLSubject.send(url)
        
    }
    
    @objc func openSettingsWindow() {
        if self.settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(spotify)
                .environmentObject(playerManager)
            self.settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
                styleMask: [
                    .titled,
                    .closable,
                    .miniaturizable,
                    .resizable,
                    .fullSizeContentView
                ],
                backing: .buffered,
                defer: false
            )
            self.settingsWindow?.center()
            self.settingsWindow?.setFrameAutosaveName("Settings")
            self.settingsWindow?.title = "Settings"
            self.settingsWindow?.isReleasedWhenClosed = false
            self.settingsWindow?.contentView = NSHostingView(rootView: settingsView)
            
        }
        assert(self.settingsWindow != nil)
        self.settingsWindow?.makeKeyAndOrderFront(nil)
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
    }

    func applicationShouldTerminate(
        _ sender: NSApplication
    ) -> NSApplication.TerminateReply {
        
        return .terminateNow

    }

}

extension AppDelegate: NSPopoverDelegate {
    
    func popoverDidClose(_ notification: Notification) {
        self.playerManager.popoverDidClose.send()
    }

}
