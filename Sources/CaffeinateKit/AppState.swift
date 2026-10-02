import Foundation
import Combine
import SwiftUI

/// Unified reactive state model shared across SwiftUI views (Dashboard Window & Popover Widget).
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var isActive: Bool = false
    @Published public var currentMode: PowerManager.SleepMode = .display
    @Published public var duration: DurationOption = .indefinite
    @Published public var remainingFormatted: String = ""
    @Published public var remainingSeconds: Double = 0
    @Published public var batteryStatus: BatteryStatus = BatteryStatus(level: nil, isCharging: false, isOnACPower: true, hasBattery: false)
    @Published public var isLowBatteryCutoffEnabled: Bool = true
    @Published public var showOnLaunch: Bool = true

    private let powerManager = PowerManager.shared
    private let batteryMonitor = BatteryMonitor.shared
    private let timerManager = TimerManager.shared
    private let sharedState = SharedStateManager.shared

    private init() {
        self.showOnLaunch = UserDefaults.standard.object(forKey: "showOnLaunch") as? Bool ?? true
        self.isLowBatteryCutoffEnabled = batteryMonitor.isLowBatteryProtectionEnabled
        self.batteryStatus = batteryMonitor.currentStatus
        self.isActive = powerManager.isActive
        self.currentMode = powerManager.currentMode

        wireListeners()
        syncToDisk()
    }

    private func wireListeners() {
        powerManager.onStateChange = { [weak self] active, mode in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isActive = active
                self.currentMode = mode
                self.syncToDisk()
            }
        }

        batteryMonitor.onBatteryStatusChanged = { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.batteryStatus = status
                self.syncToDisk()
            }
        }

        timerManager.onTick = { [weak self] remaining in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.remainingSeconds = remaining
                self.remainingFormatted = self.timerManager.formattedRemainingTime()
                self.syncToDisk()
            }
        }

        timerManager.onExpire = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.remainingSeconds = 0
                self.remainingFormatted = ""
                self.syncToDisk()
            }
        }
    }

    public func toggle() {
        if isActive {
            powerManager.deactivate()
            timerManager.stopTimer()
        } else {
            powerManager.activate(mode: currentMode)
            timerManager.start(duration: duration)
        }
        isActive = powerManager.isActive
        syncToDisk()
    }

    public func setMode(_ mode: PowerManager.SleepMode) {
        currentMode = mode
        if isActive {
            powerManager.activate(mode: mode)
        }
        syncToDisk()
    }

    public func setDuration(_ newDuration: DurationOption) {
        duration = newDuration
        if isActive {
            timerManager.start(duration: newDuration)
        }
        syncToDisk()
    }

    public func setLowBatteryCutoff(_ enabled: Bool) {
        isLowBatteryCutoffEnabled = enabled
        batteryMonitor.isLowBatteryProtectionEnabled = enabled
        syncToDisk()
    }

    public func setShowOnLaunch(_ show: Bool) {
        showOnLaunch = show
        UserDefaults.standard.set(show, forKey: "showOnLaunch")
    }

    public func syncToDisk() {
        let stateData = CaffeinateStateData(
            isActive: isActive,
            mode: currentMode.rawValue,
            durationTitle: duration.title,
            remainingSeconds: remainingSeconds,
            expirationTimestamp: timerManager.expirationDate?.timeIntervalSince1970,
            batteryLevel: batteryStatus.level,
            isCharging: batteryStatus.isCharging,
            isOnACPower: batteryStatus.isOnACPower,
            lowBatteryCutoffEnabled: isLowBatteryCutoffEnabled,
            lastUpdated: Date().timeIntervalSince1970
        )
        sharedState.save(state: stateData)
    }
}
