import Foundation
import IOKit.pwr_mgt

/// Manages native macOS power management assertions to prevent display and/or system sleep.
public final class PowerManager {
    public enum SleepMode: String, CaseIterable, Identifiable {
        case display = "display"
        case system = "system"

        public var id: String { rawValue }

        public var displayName: String {
            switch self {
            case .display:
                return "Prevent Display & System Sleep"
            case .system:
                return "Prevent System Sleep Only"
            }
        }

        public var assertionType: CFString {
            switch self {
            case .display:
                return kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
            case .system:
                return kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
            }
        }
    }

    public static let shared = PowerManager()

    private let lock = NSLock()
    private var assertionID: IOPMAssertionID = 0
    public private(set) var isActive: Bool = false
    public private(set) var currentMode: SleepMode = .display

    public var onStateChange: ((Bool, SleepMode) -> Void)?

    public init() {}

    deinit {
        deactivate()
    }

    /// Activates sleep prevention for the specified mode.
    /// If an assertion is already active with a different mode, it is cleanly replaced.
    @discardableResult
    public func activate(mode: SleepMode = .display, reason: String = "Caffeinate Sleep Prevention") -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if isActive {
            if currentMode == mode {
                return true
            }
            // Switch modes: release old assertion first
            releaseAssertion()
        }

        var newAssertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            mode.assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newAssertionID
        )

        if result == kIOReturnSuccess {
            assertionID = newAssertionID
            isActive = true
            currentMode = mode
            let currentActive = isActive
            let currentM = currentMode
            DispatchQueue.main.async { [weak self] in
                self?.onStateChange?(currentActive, currentM)
            }
            return true
        } else {
            assertionID = 0
            isActive = false
            return false
        }
    }

    /// Releases any active power management assertion and allows normal sleep behavior.
    public func deactivate() {
        lock.lock()
        defer { lock.unlock() }

        guard isActive else { return }
        releaseAssertion()
        let currentM = currentMode
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(false, currentM)
        }
    }

    /// Toggles active state. If activating and mode is omitted, uses the current or default mode.
    @discardableResult
    public func toggle(mode: SleepMode? = nil) -> Bool {
        if isActive {
            deactivate()
            return false
        } else {
            return activate(mode: mode ?? currentMode)
        }
    }

    private func releaseAssertion() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
        isActive = false
    }
}
