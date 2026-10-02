import Foundation
import CaffeinateKit

func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if !condition() {
        print("❌ Assertion Failed: \(message) at \(file):\(line)")
        exit(1)
    }
}

func assertFalse(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if condition() {
        print("❌ Assertion Failed (expected false): \(message) at \(file):\(line)")
        exit(1)
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if a != b {
        print("❌ Equality Assertion Failed: expected '\(b)', got '\(a)' - \(message) at \(file):\(line)")
        exit(1)
    }
}

print("========================================")
print("Running Caffeinate Automated Test Suite")
print("========================================")

// Test 1: PowerManager Activation and Deactivation
print("\n[TEST 1] PowerManager Activation & Mode Switching...")
let pm = PowerManager()
assertFalse(pm.isActive, "Initial state should be inactive")

let activatedDisplay = pm.activate(mode: .display, reason: "Test Display Sleep")
assertTrue(activatedDisplay, "Display activation should succeed")
assertTrue(pm.isActive, "isActive should be true")
assertEqual(pm.currentMode, .display, "currentMode should be .display")

let switchedSystem = pm.activate(mode: .system, reason: "Test System Sleep")
assertTrue(switchedSystem, "System activation should succeed")
assertTrue(pm.isActive, "isActive should remain true")
assertEqual(pm.currentMode, .system, "currentMode should be .system")

pm.deactivate()
assertFalse(pm.isActive, "isActive should be false after deactivate()")
print("  ✓ PowerManager activation, switching, and deactivation verified.")

// Test 2: PowerManager Toggle
print("\n[TEST 2] PowerManager Toggle...")
pm.deactivate()
assertFalse(pm.isActive)

let turnedOn = pm.toggle(mode: .display)
assertTrue(turnedOn, "Toggle on should return true")
assertTrue(pm.isActive, "isActive should be true after toggle")

let turnedOff = pm.toggle()
assertFalse(turnedOff, "Toggle off should return false")
assertFalse(pm.isActive, "isActive should be false after toggle")
print("  ✓ PowerManager toggle behavior verified.")

// Test 3: BatteryStatus Formatting
print("\n[TEST 3] BatteryStatus Formatting...")
let acStatus = BatteryStatus(level: nil, isCharging: false, isOnACPower: true, hasBattery: false)
assertEqual(acStatus.descriptionText, "AC Power (No Battery)")

let chargingStatus = BatteryStatus(level: 85, isCharging: true, isOnACPower: true, hasBattery: true)
assertEqual(chargingStatus.descriptionText, "85% (Charging)")

let dischargingStatus = BatteryStatus(level: 42, isCharging: false, isOnACPower: false, hasBattery: true)
assertEqual(dischargingStatus.descriptionText, "42% (Discharging)")
print("  ✓ BatteryStatus formatting verified across all power configurations.")

// Test 4: BatteryMonitor Inspection
print("\n[TEST 4] BatteryMonitor Hardware Detection...")
let monitor = BatteryMonitor()
let currentStatus = monitor.refresh()
print("  Current Hardware State: \(currentStatus.descriptionText)")
if let lvl = currentStatus.level {
    assertTrue(lvl >= 0 && lvl <= 100, "Battery level must be in 0...100 range")
}
monitor.isLowBatteryProtectionEnabled = true
monitor.lowBatteryCutoffThreshold = 20
assertEqual(monitor.lowBatteryCutoffThreshold, 20)
print("  ✓ BatteryMonitor hardware inspection & cutoff threshold verified.")

// Test 5: Duration Presets & Formatting
print("\n[TEST 5] Duration Presets & Formatted Strings...")
assertEqual(DurationOption.indefinite.title, "Indefinitely")
assertTrue(DurationOption.indefinite.seconds == nil)

let fifteen = DurationOption.minutes(15)
assertEqual(fifteen.title, "15 Minutes")
assertEqual(fifteen.seconds, 900)

let sixty = DurationOption.minutes(60)
assertEqual(sixty.title, "1 Hour")
assertEqual(sixty.seconds, 3600)

let ninety = DurationOption.minutes(90)
assertEqual(ninety.title, "1h 30m")
assertEqual(ninety.seconds, 5400)
print("  ✓ Duration presets and string conversions verified.")

// Test 6: TimerManager Lifecycle
print("\n[TEST 6] TimerManager Lifecycle...")
let tm = TimerManager()
assertFalse(tm.isTimerRunning)

tm.start(duration: .minutes(30))
assertTrue(tm.isTimerRunning)
assertTrue(tm.expirationDate != nil)
assertTrue(tm.remainingSeconds > 0)

let formatted = tm.formattedRemainingTime()
assertFalse(formatted.isEmpty)

tm.stopTimer()
assertFalse(tm.isTimerRunning)
assertTrue(tm.expirationDate == nil)
assertEqual(tm.remainingSeconds, 0)
print("  ✓ TimerManager start, formatted countdown, and stop lifecycle verified.")

// Test 7: System pmset Power Assertion Integration
print("\n[TEST 7] System pmset Power Assertion Integration...")
let pmLive = PowerManager()
assertTrue(pmLive.activate(mode: .display, reason: "Caffeinate Test Live Assertion"))

let pipe = Pipe()
let proc = Process()
proc.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
proc.arguments = ["-g", "assertions"]
proc.standardOutput = pipe
try! proc.run()
proc.waitUntilExit()

let data = pipe.fileHandleForReading.readDataToEndOfFile()
let pmsetOutput = String(data: data, encoding: .utf8) ?? ""
let foundLiveAssertion = pmsetOutput.contains("Caffeinate Test Live Assertion")
print("  pmset Live Assertion detected in powerd: \(foundLiveAssertion)")
assertTrue(foundLiveAssertion, "Active assertion must appear in system pmset registry")

pmLive.deactivate()

// Verify assertion is released
let pipe2 = Pipe()
let proc2 = Process()
proc2.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
proc2.arguments = ["-g", "assertions"]
proc2.standardOutput = pipe2
try! proc2.run()
proc2.waitUntilExit()

let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
let pmsetOutput2 = String(data: data2, encoding: .utf8) ?? ""
let stillPresent = pmsetOutput2.contains("Caffeinate Test Live Assertion")
assertFalse(stillPresent, "Assertion must be released from system pmset registry")
print("  ✓ System pmset powerd integration & clean release verified.")

// Test 8: SharedStateManager Cross-Process Persistence
print("\n[TEST 8] SharedStateManager Cross-Process Persistence...")
let sharedMgr = SharedStateManager.shared
let testState = CaffeinateStateData(
    isActive: true,
    mode: "system",
    durationTitle: "2 Hours",
    remainingSeconds: 7200,
    batteryLevel: 92,
    isCharging: true,
    isOnACPower: true,
    lowBatteryCutoffEnabled: true
)
sharedMgr.save(state: testState)

let loadedState = sharedMgr.load()
assertEqual(loadedState.isActive, true, "isActive should match saved state")
assertEqual(loadedState.mode, "system", "mode should match saved state")
assertEqual(loadedState.durationTitle, "2 Hours", "durationTitle should match")
assertEqual(loadedState.batteryLevel, 92, "batteryLevel should match")
assertEqual(loadedState.isCharging, true, "isCharging should match")
print("  ✓ SharedStateManager JSON encoding, disk persistence, and decoding verified.")

print("\n========================================")
print("🎉 ALL 8 TEST SUITES PASSED SUCCESSFULLY!")
print("========================================")
