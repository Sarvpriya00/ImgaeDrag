import AppKit
import SwiftUI
import Combine

extension Notification.Name {
    static let didReceiveDroppedProviders = Notification.Name("didReceiveDroppedProviders")
    static let openMainAppWindow = Notification.Name("openMainAppWindow")
    static let closeMenuBarPanel = Notification.Name("closeMenuBarPanel")
}

@MainActor
class MenuBarManager: NSObject {
    let sessionManager: SessionManager
    private var statusItem: NSStatusItem?
    private var myMenu: NSMenu?
    private weak var appDelegate: AnyObject?
    
    var mainWindowController: MainWindowController?
    private var cancellables = Set<AnyCancellable>()
    
    init(sessionManager: SessionManager, appDelegate: AnyObject) {
        self.sessionManager = sessionManager
        self.appDelegate = appDelegate
        super.init()
        setupStatusItem()
        observeSessionState()
        setupNotificationObservers()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: "DropSession Menu Bar Icon")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            
            // Transparent overlay to detect drag-and-drop actions
            let dragView = StatusItemDragView(frame: button.bounds)
            dragView.autoresizingMask = [.width, .height]
            dragView.onDragEnter = { [weak self] in
                self?.handleDragEntered()
            }
            dragView.onDrop = { [weak self] providers in
                self?.handleDroppedProvidersDirectly(providers)
            }
            button.addSubview(dragView)
        }
        buildMenu()
    }
    
    private func observeSessionState() {
        sessionManager.$isSessionActive
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.buildMenu()
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(openMainAppWindowNotification), name: .openMainAppWindow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeMenuBarPanelNotification), name: .closeMenuBarPanel, object: nil)
    }
    
    private func buildMenu() {
        let menu = NSMenu()
        
        if sessionManager.isSessionActive {
            let statusLabel = NSMenuItem(title: "Active: \(sessionManager.currentSessionName)", action: nil, keyEquivalent: "")
            statusLabel.isEnabled = false
            menu.addItem(statusLabel)
            
            let stopItem = NSMenuItem(title: "Stop Session", action: #selector(toggleSession), keyEquivalent: "s")
            stopItem.target = self
            menu.addItem(stopItem)
        } else {
            let statusLabel = NSMenuItem(title: "Session Inactive", action: nil, keyEquivalent: "")
            statusLabel.isEnabled = false
            menu.addItem(statusLabel)
            
            let startItem = NSMenuItem(title: "Start Session", action: #selector(toggleSession), keyEquivalent: "s")
            startItem.target = self
            menu.addItem(startItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let openMainWindowItem = NSMenuItem(title: "Open Dashboard", action: #selector(openMainWindow), keyEquivalent: "d")
        openMainWindowItem.target = self
        menu.addItem(openMainWindowItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettingsWindow), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit DropSession", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.myMenu = menu
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            if let menu = myMenu {
                menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.frame.height), in: sender)
            }
        } else {
            toggleMainWindow(sender)
        }
    }
    
    private func toggleMainWindow(_ sender: NSStatusBarButton) {
        if mainWindowController == nil {
            mainWindowController = MainWindowController(sessionManager: sessionManager)
        }
        
        if let window = mainWindowController?.window, window.isVisible {
            window.orderOut(nil)
        } else {
            mainWindowController?.show(relativeTo: sender)
        }
    }
    
    private func handleDragEntered() {
        guard let button = statusItem?.button else { return }
        if mainWindowController == nil {
            mainWindowController = MainWindowController(sessionManager: sessionManager)
        }
        mainWindowController?.show(relativeTo: button)
    }
    
    private func handleDroppedProvidersDirectly(_ providers: [NSItemProvider]) {
        if let button = statusItem?.button {
            if mainWindowController == nil {
                mainWindowController = MainWindowController(sessionManager: sessionManager)
            }
            mainWindowController?.show(relativeTo: button)
        }
        NotificationCenter.default.post(name: .didReceiveDroppedProviders, object: providers)
    }
    
    @objc private func openMainAppWindowNotification() {
        mainWindowController?.window?.orderOut(nil)
        openMainWindow()
    }
    
    @objc private func closeMenuBarPanelNotification() {
        mainWindowController?.window?.orderOut(nil)
    }
    
    @objc private func toggleSession() {
        if sessionManager.isSessionActive {
            sessionManager.stopSession()
        } else {
            sessionManager.startSession()
        }
    }
    
    @objc private func openMainWindow() {
        if let delegate = appDelegate {
            let selector = Selector(("openMainAppWindowWithTab:"))
            if delegate.responds(to: selector) {
                _ = delegate.perform(selector, with: "dashboard")
            }
        }
    }
    
    @objc private func openSettingsWindow() {
        if let delegate = appDelegate {
            let selector = Selector(("openMainAppWindowWithTab:"))
            if delegate.responds(to: selector) {
                _ = delegate.perform(selector, with: "settings")
            }
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

// Window Controller for the Drag Shelf Window (Attached, Borderless Panel)
class MainWindowController: NSObject, NSWindowDelegate {
    var window: DropSessionPanel?
    let sessionManager: SessionManager
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }
    
    func show(relativeTo button: NSButton?) {
        let newWindow = getOrCreateWindow()
        
        if let button = button, let buttonWindow = button.window {
            let buttonFrame = button.frame
            let buttonRectInScreen = buttonWindow.convertToScreen(button.convert(buttonFrame, to: nil))
            
            let windowSize = newWindow.frame.size
            let windowX = buttonRectInScreen.origin.x + (buttonRectInScreen.width / 2) - (windowSize.width / 2)
            let windowY = buttonRectInScreen.origin.y - windowSize.height - 4 // 4pt gap under menu bar
            
            newWindow.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        }
        
        // Show panel and focus text field. DO NOT call NSApp.activate, which switches desktops.
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    func getOrCreateWindow() -> DropSessionPanel {
        if let window = window {
            return window
        }
        
        let mainView = MainDropView(sessionManager: sessionManager)
            .environmentObject(sessionManager)
        
        let rect = NSRect(x: 0, y: 0, width: 440, height: 600)
        
        // Completely borderless panel to attach cleanly to the menu bar without title bars
        let newWindow = DropSessionPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        newWindow.delegate = self
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = true
        newWindow.isRestorable = false
        
        // Float above spaces and fullscreen apps
        newWindow.level = .floating
        newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newWindow.hidesOnDeactivate = false
        
        newWindow.contentView = NSHostingView(rootView: mainView)
        self.window = newWindow
        return newWindow
    }
    
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}

// Custom View to intercept drag & drop on the menu bar button
class StatusItemDragView: NSView {
    var onDragEnter: (() -> Void)?
    var onDrop: (([NSItemProvider]) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.URL, .fileURL, .png, .tiff, .string])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        onDragEnter?()
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        var providers = [NSItemProvider]()
        
        if let items = pasteboard.readObjects(forClasses: [NSURL.self, NSString.self, NSImage.self]) {
            for item in items {
                if let url = item as? URL {
                    providers.append(NSItemProvider(object: url as NSURL))
                } else if let str = item as? String {
                    providers.append(NSItemProvider(object: str as NSString))
                } else if let img = item as? NSImage {
                    providers.append(NSItemProvider(object: img))
                }
            }
        }
        
        if !providers.isEmpty {
            onDrop?(providers)
            return true
        }
        return false
    }
    
    // Forward mouse events to the next responder (the NSButton)
    override func mouseDown(with event: NSEvent) {
        nextResponder?.mouseDown(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        nextResponder?.mouseUp(with: event)
    }
}

// Custom NSPanel that allows key focus for textfields even when borderless
class DropSessionPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
