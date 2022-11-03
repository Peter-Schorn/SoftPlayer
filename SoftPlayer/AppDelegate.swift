import Cocoa
import AppKit
import SwiftUI
import Combine
import SpotifyWebAPI
import KeyboardShortcuts
import Logging
import CoreSpotlight
import CoreData

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    static var shared: AppDelegate {
        NSApplication.shared.delegate as! AppDelegate
    }

    static let popoverWidth: CGFloat = 250
    static let popoverHeight: CGFloat = 460
    
    var settingsWindow: NSWindow? = nil
    var mainWindow: NSWindow? = nil

    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    var contextMenu: NSMenu!
    
    // MARK: Environment Objects
    var spotify: Spotify!
    var playerManager: PlayerManager!

    lazy var versionBuildIdentifier: String = {
        let dictionary = Bundle.main.infoDictionary ?? [:]
        let version = dictionary["CFBundleShortVersionString"] as? String
        let build = dictionary["CFBundleVersion"] as? String
        var result = ""
        if let version = version {
            result += version
        }
        if let build = build {
            result += " (\(build))"
        }
        return result
    }()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer.init(name: "DataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        container.newBackgroundContext()

        return container
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        let context = self.persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        return context
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        SoftPlayerLogHandler.bootstrap()
        // spotifyDecodeLogger.logLevel = .trace
        // SwiftLogNoOpLogHandler.bootstrap()

        self.initializeKeyboardShortcutNames()

        self.configureContextMenu()

        self.spotify = Spotify()

        self.playerManager = PlayerManager(
            spotify: spotify
        )
        
        // MARK: Root View
        let rootView = RootView()
            .environmentObject(self.spotify)
            .environmentObject(self.playerManager)
            
        let popover = NSPopover()
        popover.contentSize = CGSize(
            width: Self.popoverWidth, height: Self.popoverHeight
        )
        popover.behavior = .transient
//        popover.behavior = .applicationDefined
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
            Loggers.appDelegate.critical(
                "AppDelegate.statusBarItem.button was nil"
            )
        }
        
        self.registerGlobalKeyboardShortcutHandler()

        let _ = self.versionBuildIdentifier

    }
    
    func application(
        _ application: NSApplication,
        willContinueUserActivityWithType userActivityType: String
    ) -> Bool {
        return userActivityType == CSSearchableItemActionType
    }
    
    func application(
        _ application: NSApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([NSUserActivityRestoring]) -> Void
    ) -> Bool {
        
        guard userActivity.activityType == CSSearchableItemActionType else {
            return false
        }

        return self.playerManager.continueUserActivity(userActivity)
    }

    func registerGlobalKeyboardShortcutHandler() {
        KeyboardShortcuts.onKeyDown(for: .openApp) {
            self.togglePopover(nil)
        }
  
    }
    
    func configureContextMenu() {
        
        self.contextMenu = NSMenu(
            title: NSLocalizedString("Options", comment: "")
        )
        
        if ProcessInfo.processInfo.isPreviewing {
            self.contextMenu.addItem(
                withTitle: "Preview Build",
                action: nil,
                keyEquivalent: ""
            )
        }
        
        self.contextMenu.addItem(
            withTitle: NSLocalizedString("Open in Window", comment: ""),
            action: #selector(self.openInWindow),
            keyEquivalent: ""
        )
        .setShortcut(for: .openInWindow)

        self.contextMenu.addItem(
            withTitle: NSLocalizedString("Settings", comment: ""),
            action: #selector(self.openSettingsWindow),
            keyEquivalent: ""
        )
        .setShortcut(for: .settings)
        
        self.contextMenu.addItem(
            withTitle: NSLocalizedString("Quit", comment: ""),
            action: #selector(NSApplication.shared.terminate(_:)),
            keyEquivalent: ""
        )
        .setShortcut(for: .quit)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        self.playerManager.spotifyApplication?.blockAppleEvents = true
        self.playerManager.playerStateDidChangeCancellable = nil
        self.playerManager.commitModifiedDates()
        self.playerManager.saveViewContext()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        
        guard let url = urls.first else {
            Loggers.appDelegate.error("application open urls: urls was empty")
            return
        }
        
        guard url.scheme == spotify.loginCallbackURL.scheme else {
            Loggers.appDelegate.error("unsupported URL: \(url)")
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
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.settingsWindow?.makeKeyAndOrderFront(nil)

    }
    
    @objc func openInWindow() {
        
        self.closePopover()

        if self.mainWindow == nil {
            
            let rootView = RootView()
                .environmentObject(self.spotify)
                .environmentObject(self.playerManager)
            
            self.mainWindow = NSWindow(
                contentRect: CGRect(
                    x: 0,
                    y: 0,
                    width: AppDelegate.popoverWidth,
                    height: AppDelegate.popoverHeight
                ),
                styleMask: [
                    .titled,
                    .closable,
                    .miniaturizable,
                    .fullSizeContentView
                ],
                backing: .buffered,
                defer: false
            )
            
            self.mainWindow?.title = "Soft Player"
            self.mainWindow?.setFrameAutosaveName("Soft Player")
            self.mainWindow?.isReleasedWhenClosed = false
            self.mainWindow?.center()
            self.mainWindow?.contentView = NSHostingView(rootView: rootView)
        }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.mainWindow?.makeKeyAndOrderFront(nil)
        
    }
    
    /// Global variables are lazily initialized, but this program relies on the
    /// keyboard shortcut names being initialized immediately.
    func initializeKeyboardShortcutNames() {
        typealias Name = KeyboardShortcuts.Name
        var sink = ""
        print(Name.openApp, to: &sink)
        print(Name.openInWindow, to: &sink)
        print(Name.showLibrary, to: &sink)
        print(Name.previousTrack, to: &sink)
        print(Name.playPause, to: &sink)
        print(Name.nextTrack, to: &sink)
        print(Name.repeatMode, to: &sink)
        print(Name.shuffle, to: &sink)
        print(Name.likeTrack, to: &sink)
        print(Name.volumeDown, to: &sink)
        print(Name.volumeUp, to: &sink)
        print(Name.onlyShowMyPlaylists, to: &sink)
        print(Name.settings, to: &sink)
        print(Name.quit, to: &sink)
        print(Name.undo, to: &sink)
        print(Name.redo, to: &sink)
    }

}

// MARK: - Popover -

extension AppDelegate: NSPopoverDelegate {
    
    @objc func togglePopover(_ sender: AnyObject?) {


        if
            let event = NSApplication.shared.currentEvent,
            event.type == .rightMouseDown ||
            (event.type == .leftMouseDown && event.modifierFlags.contains(.control))
        {
            // then the user right-clicked on the status bar item
            Loggers.appDelegate.trace("toggle popover right click")

            self.statusBarItem.menu = self.contextMenu
            self.statusBarItem.button?.performClick(nil)
            self.statusBarItem.menu = nil

        }
        else {
            // assume the user left-clicked on the status bar item
            Loggers.appDelegate.trace("toggle popover left click")


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
            Loggers.appDelegate.critical(
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

// MARK: - Lifecyle -

extension AppDelegate {
    
    func applicationWillBecomeActive(_ notification: Notification) {
        Loggers.lifeCycle.trace("applicationWillBecomeActive")
    }
    func applicationDidBecomeActive(_ notification: Notification) {
        Loggers.lifeCycle.trace("applicationDidBecomeActive")
    }
    func applicationWillResignActive(_ notification: Notification) {
        Loggers.lifeCycle.trace("applicationWillResignActive")
    }
    func applicationDidResignActive(_ notification: Notification) {
        Loggers.lifeCycle.trace("applicationDidResignActive")
    }

}
