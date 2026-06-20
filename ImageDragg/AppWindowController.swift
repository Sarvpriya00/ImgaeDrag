import AppKit
import SwiftUI

class AppWindowController: NSObject, NSWindowDelegate {
    var window: NSWindow?
    let sessionManager: SessionManager
    private weak var appDelegate: AnyObject?
    
    init(sessionManager: SessionManager, appDelegate: AnyObject) {
        self.sessionManager = sessionManager
        self.appDelegate = appDelegate
        super.init()
    }
    
    func show(tab: String = "dashboard") {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let mainView = MainAppWindowView(sessionManager: sessionManager, selectedTab: tab)
        
        let rect = NSRect(x: 0, y: 0, width: 750, height: 500)
        let newWindow = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        newWindow.delegate = self
        newWindow.title = "DropSession"
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.isMovableByWindowBackground = true
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        
        newWindow.contentView = NSHostingView(rootView: mainView)
        newWindow.center()
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        window = nil
        // Notify appDelegate dynamically using selector or cast to AppDelegate
        if let delegate = appDelegate {
            let selector = Selector(("mainAppWindowWillClose"))
            if delegate.responds(to: selector) {
                _ = delegate.perform(selector)
            }
        }
    }
}
