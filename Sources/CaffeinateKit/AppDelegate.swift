import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Enforce menu bar accessory mode (no Dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)
        StatusBarController.shared.setup()

        // Show the popup UI at first launch by default
        if AppState.shared.showOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                DashboardWindowController.shared.show()
            }
        }
    }

    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "caffeinate" else { continue }
            switch url.host {
            case "toggle":
                AppState.shared.toggle()
            case "activate":
                if !AppState.shared.isActive { AppState.shared.toggle() }
            case "deactivate":
                if AppState.shared.isActive { AppState.shared.toggle() }
            case "dashboard":
                DashboardWindowController.shared.show()
            default:
                break
            }
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        PowerManager.shared.deactivate()
        TimerManager.shared.stopTimer()
        BatteryMonitor.shared.stopMonitoring()
    }
}
