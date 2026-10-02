# 📋 Product Requirements Document (PRD)

## Document Metadata
* **Product Name**: Caffeinate for macOS
* **Version**: 1.1.0 (Production Release)
* **Document Status**: Approved / Implemented
* **Target Platforms**: macOS 13.0+ (Ventura, Sonoma, Sequoia, and future versions)
* **Architecture**: Apple Silicon (`arm64`) & Universal Binary Ready

---

## 1. Executive Summary & Product Vision

Modern macOS operating systems enforce aggressive sleep policies to conserve power. While beneficial for battery life, this behavior frequently disrupts critical tasks: presentations dim unexpectedly, long compiles terminate prematurely, and large cloud backups stall. 

**Caffeinate** is built to solve this problem cleanly: a native, ultra-lightweight macOS utility that keeps your Mac awake on your exact terms. Combining a discreet menu bar status icon, an interactive first-launch dashboard, and modern macOS desktop and notification center widgets, Caffeinate provides granular sleep prevention with zero external dependencies and guaranteed battery safety.

---

## 2. Target User Personas

| Persona | Role / Description | Primary Goal | Pain Points with Existing Solutions |
| :--- | :--- | :--- | :--- |
| **P1: The Software Engineer** | Compiles large Swift/Rust/C++ codebases, runs Docker containers, and performs multi-gigabyte data migrations. | Wants the Mac to stay awake for a 1-hour background job while allowing the display to sleep to preserve panel life. | Existing tools keep the screen at full brightness, wasting display hours and battery. |
| **P2: The Executive / Presenter** | Delivers keynote presentations, client demos, and leads Zoom/Teams conferences. | Wants 100% confidence that the screen will not lock or sleep mid-presentation. | Changing macOS System Settings takes 6+ clicks and is frequently forgotten afterward. |
| **P3: The Media & Creative Pro** | Video editors (Final Cut / Premiere) and 3D animators (Blender) executing overnight renders. | Needs continuous CPU/GPU activity with automated shutdown protection if running on battery. | Forgetting to plug in AC power can lead to battery drain down to 0% and corrupt render caches. |
| **P4: The Everyday Mac User** | Considers complex tools like Amphetamine overly cluttered with confusing triggers. | Wants a clean, friendly coffee cup icon that turns on with one click and looks native to macOS. | Legacy tools feel dated, lack Sonoma/Sequoia desktop widgets, and launch unwanted Dock icons. |

---

## 3. Product Scope & User Journey

### 3.1 First Launch Experience
1. User downloads or copies `Caffeinate.app` to `/Applications` and launches it.
2. The app initializes as an `LSUIElement` accessory (no Dock clutter).
3. The **Caffeinate Dashboard Popup UI** automatically presents in the center of the display:
   - Welcomes the user with the glowing espresso cup logo.
   - Highlights the current status (**IDLE**).
   - Allows instant one-click activation.
   - User chooses their preferred mode and duration, then clicks **"Minimize to Menu Bar"**.
4. The dashboard smoothly dismisses, leaving the coffee cup status icon active in the menu bar.

### 3.2 Daily Usage Flow (Menu Bar)
* **Left-Click Status Icon**: Opens the compact **Menu Bar Popover Widget** for instant duration adjustments, mode switching, or quick deactivation.
* **Right-Click / Option-Click Status Icon**: Opens the full AppKit context menu (accessing settings, opening the dashboard, or quitting).

### 3.3 Desktop & Notification Center Interaction
* User adds the **Caffeinate Widget** to their desktop or Notification Center.
* Widget displays real-time status (**AWAKE** vs **IDLE**), remaining session time, and battery percentage.
* Tapping the widget immediately toggles Caffeinate without opening any windows.

---

## 4. Detailed Functional Specifications

### FR-1: Visual Identity & Iconography
* **Requirement**: Provide a high-resolution, modern macOS app icon and dynamic menu bar symbols.
* **Acceptance Criteria**:
  - `AppIcon.icns` multi-layer bundle supporting resolutions from 16x16 up to 1024x1024 (@1x and @2x).
  - Modern squircle styling with glassmorphism dark background and amber/cyan neon coffee steam.
  - Menu bar icon adapts automatically to macOS Light and Dark appearance via template SF Symbols (`cup.and.saucer` / `cup.and.saucer.fill`).

### FR-2: First-Launch Popup Dashboard (`DashboardView`)
* **Requirement**: Automatically open a floating configuration window upon application start.
* **Acceptance Criteria**:
  - Hosted in an `NSPanel` centered on screen with `.hudWindow` frosted glass vibrancy.
  - Contains large one-tap toggle button with animated amber glow when active.
  - Sleep mode segmented buttons: **Display & System** vs. **System Only**.
  - Duration preset buttons: **Indefinite**, **15m**, **30m**, **1h**, **2h**, **4h**.
  - Battery gauge with **Auto-disable below 20% battery** protection toggle.
  - Checkbox: "Show on launch" (persisted in `UserDefaults`).
  - Button: "Minimize to Menu Bar" smoothly dismisses the panel.

### FR-3: Sleep Prevention Modes
* **Requirement**: Provide two distinct sleep assertion levels via native IOKit.
* **Acceptance Criteria**:
  - **Mode 1 (`display`)**: Holds `kIOPMAssertionTypePreventUserIdleDisplaySleep`. Screen and system remain awake.
  - **Mode 2 (`system`)**: Holds `kIOPMAssertionTypePreventUserIdleSystemSleep`. System stays awake, display follows OS energy timer.
  - Mode switches must execute dynamically without interrupting session timers.

### FR-4: Session Timers & Presets
* **Requirement**: Support predetermined durations and indefinite sessions.
* **Acceptance Criteria**:
  - Presets: Indefinitely, 15 Minutes, 30 Minutes, 1 Hour, 2 Hours, 4 Hours.
  - Real-time countdown timer running at 1Hz interval.
  - Formatted countdown displayed in menu bar and widget (e.g., `14:32` or `1h 45m`).
  - Auto-deactivation and system notification upon timer expiration.

### FR-5: Low Battery Protection Subsystem
* **Requirement**: Prevent accidental laptop battery depletion.
* **Acceptance Criteria**:
  - Interrogates `IOKit.ps` hardware power sources every 30 seconds.
  - When running on battery power (discharging) and capacity drops to $\le 20\%$:
    1. Immediately releases all kernel power assertions.
    2. Invalidates active session timers.
    3. Dispatches a high-priority system notification alerting the user.

### FR-6: Menu Bar Controller & Popover Widget
* **Requirement**: Provide instant menu bar control without requiring full window navigation.
* **Acceptance Criteria**:
  - Left-click on status item displays compact SwiftUI `NSPopover` with quick toggle, mode chips, duration pills, and battery status.
  - Right-click or Option-click displays traditional AppKit menu with direct actions and "Quit Caffeinate".

### FR-7: macOS WidgetKit Desktop & Notification Center Integration
* **Requirement**: Enable users to view and toggle Caffeinate directly from the macOS desktop widget gallery.
* **Acceptance Criteria**:
  - Standalone `CaffeinateWidget.appex` bundled inside `Contents/PlugIns/`.
  - Supports `.systemSmall` and `.systemMedium` widget families.
  - Synchronizes state with main application via atomic JSON writes to `~/Library/Application Support/Caffeinate/state.json`.
  - Instant timeline reloads triggered via `WidgetCenter.shared.reloadAllTimelines()`.
  - Deep link execution via `.widgetURL(URL(string: "caffeinate://toggle"))`.

### FR-8: Custom URL Scheme Deep Linking
* **Requirement**: Allow external scripts, shortcuts, and widgets to control Caffeinate programmatically.
* **Acceptance Criteria**:
  - Registered scheme `caffeinate://` in `Info.plist`.
  - Handlers supported:
    - `caffeinate://toggle`: Toggles active state.
    - `caffeinate://activate`: Forces sleep prevention on.
    - `caffeinate://deactivate`: Forces sleep prevention off.
    - `caffeinate://dashboard`: Re-opens the floating dashboard window.

---

## 5. Non-Functional Requirements (NFR)

| ID | Metric | Target | Verification Method |
| :--- | :--- | :--- | :--- |
| **NFR-1** | **CPU Utilization** | $< 0.1\%$ idle / active | Activity Monitor inspection during active session. |
| **NFR-2** | **Memory Footprint** | $< 35\text{ MB}$ RSS | Memory profiling via Xcode Instruments / vmmap. |
| **NFR-3** | **Binary Payload Size** | $< 2\text{ MB}$ total bundle | Uncompressed bundle check (`du -sh build/Caffeinate.app`). |
| **NFR-4** | **Power Assertion Latency** | $< 5\text{ ms}$ activation time | Kernel `pmset -g assertions` timestamp comparison. |
| **NFR-5** | **Zero Telemetry / Privacy** | 0 outbound network requests | Packet capture / Little Snitch audit (app has zero network frameworks). |
| **NFR-6** | **Reliability & Crash Safety** | Clean assertion release on exit | Signal testing (`kill -2`, `kill -15`) confirms no dangling wake locks. |

---

## 6. Edge Cases & Exception Handling

1. **Abrupt App Termination**:
   - If user force-quits or terminal sends `SIGKILL`, the Darwin kernel automatically removes process assertions registered to that PID, ensuring the Mac never gets stuck in a permanent wake state.
2. **MacBook Clamshell Mode**:
   - When a MacBook lid is closed while connected to external power and display, `PreventUserIdleDisplaySleep` preserves external monitor output cleanly.
3. **Hardware Battery Absence (Desktop Macs)**:
   - On iMac, Mac mini, Mac Studio, or Mac Pro, `BatteryMonitor` detects absence of battery and gracefully displays "AC Power (No Battery)" without error.
4. **Widget Process Separation**:
   - If the main app is closed and the user taps the widget, macOS executes the URL scheme `caffeinate://toggle`, automatically launching the main app and toggling sleep prevention.
