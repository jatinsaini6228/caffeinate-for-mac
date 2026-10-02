import Foundation
import IOKit.ps

public struct BatteryStatus: Equatable {
    public let level: Int?          // 0 - 100 percentage
    public let isCharging: Bool
    public let isOnACPower: Bool
    public let hasBattery: Bool

    public init(level: Int?, isCharging: Bool, isOnACPower: Bool, hasBattery: Bool) {
        self.level = level
        self.isCharging = isCharging
        self.isOnACPower = isOnACPower
        self.hasBattery = hasBattery
    }

    public var descriptionText: String {
        guard hasBattery, let lvl = level else {
            return "AC Power (No Battery)"
        }
        let chargingState = isCharging ? "Charging" : (isOnACPower ? "On AC" : "Discharging")
        return "\(lvl)% (\(chargingState))"
    }
}

/// Monitors macOS battery level and power source states to trigger low-battery safety cutoffs.
public final class BatteryMonitor {
    public static let shared = BatteryMonitor()

    public var lowBatteryCutoffThreshold: Int = 20
    public var isLowBatteryProtectionEnabled: Bool = true

    public private(set) var currentStatus: BatteryStatus = BatteryStatus(
        level: nil,
        isCharging: false,
        isOnACPower: true,
        hasBattery: false
    )

    public var onBatteryStatusChanged: ((BatteryStatus) -> Void)?
    public var onLowBatteryTriggered: ((Int) -> Void)?

    private var pollTimer: Timer?

    public init() {
        refresh()
    }

    deinit {
        stopMonitoring()
    }

    public func startMonitoring(interval: TimeInterval = 30.0) {
        stopMonitoring()
        refresh()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    public func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    @discardableResult
    public func refresh() -> BatteryStatus {
        let status = readBatteryStatus()
        let oldStatus = currentStatus
        currentStatus = status

        if status != oldStatus {
            DispatchQueue.main.async { [weak self] in
                self?.onBatteryStatusChanged?(status)
            }
        }

        // Check if low battery protection should trigger
        if isLowBatteryProtectionEnabled,
           status.hasBattery,
           !status.isOnACPower,
           !status.isCharging,
           let lvl = status.level,
           lvl <= lowBatteryCutoffThreshold {
            DispatchQueue.main.async { [weak self] in
                self?.onLowBatteryTriggered?(lvl)
            }
        }

        return status
    }

    private func readBatteryStatus() -> BatteryStatus {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            return BatteryStatus(level: nil, isCharging: false, isOnACPower: true, hasBattery: false)
        }

        for source in sources {
            guard let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            let type = desc[kIOPSTypeKey] as? String
            let current = desc[kIOPSCurrentCapacityKey] as? Int
            let max = desc[kIOPSMaxCapacityKey] as? Int
            let isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
            let powerSourceState = desc[kIOPSPowerSourceStateKey] as? String

            let isOnAC = (powerSourceState == kIOPSACPowerValue)

            if type == kIOPSInternalBatteryType, let cur = current, let m = max, m > 0 {
                let percent = Int((Double(cur) / Double(m)) * 100.0)
                return BatteryStatus(
                    level: percent,
                    isCharging: isCharging,
                    isOnACPower: isOnAC,
                    hasBattery: true
                )
            }
        }

        return BatteryStatus(level: nil, isCharging: false, isOnACPower: true, hasBattery: false)
    }
}
