import AppKit
import SwiftUI
import UserNotifications

/// Controls the macOS menu bar status item, dynamic menu hierarchy, widget popover, and event routing.
public final class StatusBarController: NSObject, NSMenuDelegate {
    public static let shared = StatusBarController()

    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let popover = NSPopover()

    private let powerManager = PowerManager.shared
    private let batteryMonitor = BatteryMonitor.shared
    private let timerManager = TimerManager.shared

    // Menu Item References for dynamic updating
    private var statusHeaderItem: NSMenuItem?
    private var countdownItem: NSMenuItem?
    private var batteryItem: NSMenuItem?
    private var toggleActionItem: NSMenuItem?
    private var modeDisplayItem: NSMenuItem?
    private var modeSystemItem: NSMenuItem?
    private var durationMenuItems: [DurationOption: NSMenuItem] = [:]
    private var lowBatteryToggleItem: NSMenuItem?

    public override init() {
        super.init()
    }

    public func setup() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menu.delegate = self
        buildMenu()

        // Setup interactive Widget Popover
        popover.contentSize = NSSize(width: 290, height: 215)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: PopoverWidgetView(onOpenDashboard: { [weak self] in
                self?.popover.performClose(nil)
                DashboardWindowController.shared.show()
            })
        )

        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        wireCallbacks()
        batteryMonitor.startMonitoring()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        updateUI()
    }

    private func wireCallbacks() {
        powerManager.onStateChange = { [weak self] _, _ in
            self?.updateUI()
        }

        batteryMonitor.onBatteryStatusChanged = { [weak self] _ in
            self?.updateBatteryItem()
        }

        batteryMonitor.onLowBatteryTriggered = { [weak self] percent in
            guard let self = self, self.powerManager.isActive else { return }
            self.powerManager.deactivate()
            self.timerManager.stopTimer()
            self.showNotification(
                title: "Caffeinate Deactivated",
                message: "Low battery protection triggered (Battery at \(percent)%). Sleep prevention disabled."
            )
        }

        timerManager.onTick = { [weak self] _ in
            self?.updateCountdownDisplay()
        }

        timerManager.onExpire = { [weak self] in
            guard let self = self else { return }
            self.powerManager.deactivate()
            self.showNotification(
                title: "Caffeinate Timer Finished",
                message: "Scheduled caffeinate session has ended. Mac can now sleep normally."
            )
            self.updateUI()
        }
    }

    private func buildMenu() {
        menu.removeAllItems()
        durationMenuItems.removeAll()

        // 1. Status Header
        let statusItem = NSMenuItem(title: "Status: Inactive", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        self.statusHeaderItem = statusItem

        // 2. Countdown Info (hidden if indefinite or inactive)
        let countdown = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        countdown.isHidden = true
        countdown.isEnabled = false
        menu.addItem(countdown)
        self.countdownItem = countdown

        // 3. Battery Info
        let battery = NSMenuItem(title: "Battery: Checking...", action: nil, keyEquivalent: "")
        battery.isEnabled = false
        menu.addItem(battery)
        self.batteryItem = battery

        menu.addItem(NSMenuItem.separator())

        // 4. Primary Quick Toggle
        let toggle = NSMenuItem(
            title: "Activate Caffeinate",
            action: #selector(toggleCaffeinateAction),
            keyEquivalent: "t"
        )
        toggle.target = self
        menu.addItem(toggle)
        self.toggleActionItem = toggle

        menu.addItem(NSMenuItem.separator())

        // 5. Sleep Mode Submenu
        let modeMenu = NSMenu(title: "Sleep Prevention Mode")
        let displayMode = NSMenuItem(
            title: "Prevent Display & System Sleep",
            action: #selector(selectDisplayMode),
            keyEquivalent: ""
        )
        displayMode.target = self
        modeMenu.addItem(displayMode)
        self.modeDisplayItem = displayMode

        let systemMode = NSMenuItem(
            title: "Prevent System Sleep Only (Allow Display Sleep)",
            action: #selector(selectSystemMode),
            keyEquivalent: ""
        )
        systemMode.target = self
        modeMenu.addItem(systemMode)
        self.modeSystemItem = systemMode

        let modeParentItem = NSMenuItem(title: "Sleep Mode", action: nil, keyEquivalent: "")
        modeParentItem.submenu = modeMenu
        menu.addItem(modeParentItem)

        // 6. Duration Submenu
        let durationMenu = NSMenu(title: "Duration")
        for option in DurationOption.standardPresets {
            let item = NSMenuItem(
                title: option.title,
                action: #selector(selectDurationAction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option
            durationMenu.addItem(item)
            durationMenuItems[option] = item
        }
        let durationParentItem = NSMenuItem(title: "Duration", action: nil, keyEquivalent: "")
        durationParentItem.submenu = durationMenu
        menu.addItem(durationParentItem)

        menu.addItem(NSMenuItem.separator())

        // 7. Low Battery Protection Toggle
        let lowBattery = NSMenuItem(
            title: "Auto-Disable when Battery ≤ 20%",
            action: #selector(toggleLowBatteryProtection),
            keyEquivalent: ""
        )
        lowBattery.target = self
        lowBattery.state = batteryMonitor.isLowBatteryProtectionEnabled ? .on : .off
        menu.addItem(lowBattery)
        self.lowBatteryToggleItem = lowBattery

        menu.addItem(NSMenuItem.separator())

        // 8. Open Dashboard
        let dashboardItem = NSMenuItem(title: "Open Caffeinate Dashboard...", action: #selector(openDashboardAction), keyEquivalent: "o")
        dashboardItem.target = self
        menu.addItem(dashboardItem)

        menu.addItem(NSMenuItem.separator())

        // 9. Quit
        let quitItem = NSMenuItem(title: "Quit Caffeinate", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    public func updateUI() {
        guard let button = statusItem?.button else { return }

        let isActive = powerManager.isActive
        let mode = powerManager.currentMode

        // Update Icon
        let symbolName = isActive ? "cup.and.saucer.fill" : "cup.and.saucer"
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Caffeinate") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = isActive ? "☕" : "💤"
        }

        // Update Header & Toggle Action
        if isActive {
            let modeText = (mode == .display) ? "Display & System Awake" : "System Awake Only"
            statusHeaderItem?.title = "Status: Active (\(modeText))"
            toggleActionItem?.title = "Deactivate Caffeinate"
        } else {
            statusHeaderItem?.title = "Status: Inactive"
            toggleActionItem?.title = "Activate Caffeinate"
        }

        // Update Mode Checkmarks
        modeDisplayItem?.state = (mode == .display) ? .on : .off
        modeSystemItem?.state = (mode == .system) ? .on : .off

        // Update Duration Checkmarks
        let currentDuration = timerManager.activeDuration
        for (option, item) in durationMenuItems {
            item.state = (option == currentDuration) ? .on : .off
        }

        // Update Countdown
        updateCountdownDisplay()
        updateBatteryItem()
    }

    private func updateCountdownDisplay() {
        if powerManager.isActive && timerManager.isTimerRunning {
            countdownItem?.isHidden = false
            countdownItem?.title = "⏳ Remaining: \(timerManager.formattedRemainingTime())"
        } else {
            countdownItem?.isHidden = true
            countdownItem?.title = ""
        }
    }

    private func updateBatteryItem() {
        let status = batteryMonitor.currentStatus
        batteryItem?.title = "Battery: \(status.descriptionText)"
    }

    // MARK: - Actions

    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp ||
            (event?.modifierFlags.contains(.control) ?? false) ||
            (event?.modifierFlags.contains(.option) ?? false) {
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    @objc private func openDashboardAction() {
        DashboardWindowController.shared.show()
    }

    @objc private func toggleCaffeinateAction() {
        AppState.shared.toggle()
        updateUI()
    }

    @objc private func selectDisplayMode() {
        AppState.shared.setMode(.display)
        updateUI()
    }

    @objc private func selectSystemMode() {
        AppState.shared.setMode(.system)
        updateUI()
    }

    @objc private func selectDurationAction(_ sender: NSMenuItem) {
        guard let duration = sender.representedObject as? DurationOption else { return }
        AppState.shared.setDuration(duration)
        if !powerManager.isActive {
            AppState.shared.toggle()
        }
        updateUI()
    }

    @objc private func toggleLowBatteryProtection() {
        AppState.shared.setLowBatteryCutoff(!batteryMonitor.isLowBatteryProtectionEnabled)
        lowBatteryToggleItem?.state = batteryMonitor.isLowBatteryProtectionEnabled ? .on : .off
        batteryMonitor.refresh()
    }

    @objc private func quitApp() {
        powerManager.deactivate()
        timerManager.stopTimer()
        batteryMonitor.stopMonitoring()
        NSApplication.shared.terminate(nil)
    }

    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    public func menuWillOpen(_ menu: NSMenu) {
        batteryMonitor.refresh()
        updateUI()
    }
}
