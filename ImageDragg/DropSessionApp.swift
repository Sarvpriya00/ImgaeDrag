import SwiftUI
import AppKit

@main
struct DropSessionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // A placeholder Settings scene keeps the app window-less on launch
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let sessionManager = SessionManager()
    var menuBarManager: MenuBarManager?
    var appWindowController: AppWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Operates as accessory (menu-bar only) initially on launch
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status bar item and panel
        menuBarManager = MenuBarManager(sessionManager: sessionManager, appDelegate: self)
        
        // Open the Main App Window on fresh launch
        openMainAppWindow()
    }
    
    @objc func openMainAppWindowWithTab(_ tab: String) {
        if appWindowController == nil {
            appWindowController = AppWindowController(sessionManager: sessionManager, appDelegate: self)
        }
        
        // Elevate policy to regular so the Dock icon appears
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        appWindowController?.show(tab: tab)
    }
    
    @objc func openMainAppWindow() {
        openMainAppWindowWithTab("dashboard")
    }
    
    @objc func mainAppWindowWillClose() {
        appWindowController = nil
        // Return to accessory mode when the window is closed to hide the Dock icon
        NSApp.setActivationPolicy(.accessory)
    }
    
    // Handled when the user clicks the Dock icon while the app is running
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openMainAppWindow()
        return true
    }
}
