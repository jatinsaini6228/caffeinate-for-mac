import AppKit
import SwiftUI

/// Controls the floating Dashboard Window presented upon application launch and on-demand.
public final class DashboardWindowController: NSObject, NSWindowDelegate {
    public static let shared = DashboardWindowController()

    private var window: NSPanel?

    public override init() {
        super.init()
    }

    public func show() {
        if window == nil {
            createWindow()
        }

        guard let window = window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        window?.orderOut(nil)
    }

    public func toggle() {
        if let window = window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func createWindow() {
        let dashboardView = DashboardView(onClose: { [weak self] in
            self?.hide()
        })

        let hostingController = NSHostingController(rootView: dashboardView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 530),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Caffeinate"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.animationBehavior = .utilityWindow
        panel.contentViewController = hostingController
        panel.delegate = self

        self.window = panel
    }

    public func windowWillClose(_ notification: Notification) {
        // App continues running in background/menu bar
    }
}
