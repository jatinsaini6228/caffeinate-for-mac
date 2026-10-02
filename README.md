# ☕ Caffeinate for macOS

A native, ultra-lightweight macOS menu bar utility that prevents your Mac from sleeping. Built with **Swift 6**, **SwiftUI**, **AppKit**, and Apple's native **IOKit** and **WidgetKit** frameworks.

---

## ✨ Features

- **🎨 Modern App Logo & Visual Identity**:
  - High-resolution `.icns` and PNG asset featuring a glowing neon espresso cup with glassmorphism squircle styling (`Resources/AppIcon.icns`).
  - Appears in Finder, macOS Notification Center, and inside the Dashboard.
- **🚀 First-Launch Popup UI (Interactive Dashboard)**:
  - Automatically opens when the application starts up.
  - Floating translucent window with large one-tap activate/deactivate toggle, animated glowing aura, and live status badge.
  - Select sleep modes: **Display & System Sleep** vs. **System Sleep Only**.
  - Quick duration presets: **Indefinite**, **15m**, **30m**, **1h**, **2h**, **4h**.
  - Battery gauge with **Auto-disable below 20% battery** protection toggle.
  - "Show on launch" preference checkbox and "Minimize to Menu Bar" button.
- **🧩 Dual Widget Support**:
  1. **Menu Bar Popover Widget**: Click the coffee cup in your status bar to open a compact Control Center-style widget card.
  2. **macOS WidgetKit Extension (`CaffeinateWidget.appex`)**: Native desktop & Notification Center widget (`.systemSmall` and `.systemMedium`) in macOS's **Widget Gallery / Widget list**, with live status, battery indicator, and one-tap toggle.
- **⚡ In-Process IOKit Assertions**: Uses native Apple `IOPMAssertionCreateWithName` and `IOPMAssertionRelease` (`kIOPMAssertionTypePreventUserIdleDisplaySleep` and `kIOPMAssertionTypePreventUserIdleSystemSleep`). Zero external process spawns, instant response, and zero CPU overhead.
- **🔋 Low Battery Protection**:
  - Real-time battery status (`IOKit.ps` monitor).
  - Automatically disables sleep prevention when battery level drops $\le 20\%$ while discharging.
- **🔔 Native System Notifications**: Modern `UserNotifications` alert when scheduled timers expire or low battery protection triggers.

---

## 🏗️ Architecture

```
projects/caffeinate/
├── Package.swift                         # Swift Package Manager manifest
├── Resources/
│   ├── AppIcon.icns                      # macOS multi-resolution icon bundle
│   └── app_logo.png                      # High-resolution PNG logo
├── Sources/
│   ├── Caffeinate/                       # Executable target
│   │   └── main.swift                    # App bootstrap & signal handlers
│   ├── CaffeinateKit/                    # Core library
│   │   ├── AppDelegate.swift             # AppKit lifecycle, URL router, popup trigger
│   │   ├── AppState.swift                # Reactive ObservableObject state model
│   │   ├── BatteryMonitor.swift          # IOKit.ps power source detection & cutoff
│   │   ├── DashboardView.swift           # First-launch popup SwiftUI dashboard
│   │   ├── DashboardWindowController.swift # Floating NSPanel window manager
│   │   ├── PopoverWidgetView.swift       # Menu bar interactive widget popover
│   │   ├── PowerManager.swift            # IOKit.pwr_mgt sleep assertion controller
│   │   ├── SharedStateManager.swift      # Cross-process JSON sync (~/Library/Application Support/Caffeinate/state.json)
│   │   ├── StatusBarController.swift     # NSStatusItem, NSPopover & context menu
│   │   └── TimerManager.swift            # Countdown timers, presets & formatting
│   ├── CaffeinateWidget/                 # WidgetKit Extension
│   │   └── CaffeinateWidget.swift        # Desktop & Notification Center widget
│   └── CaffeinateTestRunner/             # Automated test suite (all 8 suites)
│       └── main.swift
└── scripts/
    └── build_app.sh                      # Release bundler for Caffeinate.app & CaffeinateWidget.appex
```

---

## 🚀 Building & Running

### Option 1: Package as a Standalone macOS App Bundle (`Caffeinate.app`)
Run the packaging script to generate a signed release bundle with the embedded WidgetKit extension:
```bash
./scripts/build_app.sh
```

To launch the app (will open the Popup Dashboard UI automatically):
```bash
open build/Caffeinate.app
```

To install into `/Applications` (enables the widget in macOS Desktop & Notification Center "Edit Widgets" list):
```bash
cp -R build/Caffeinate.app /Applications/
```

### Option 2: Swift Package Manager (CLI / Development)
Run directly from terminal during development:
```bash
swift run Caffeinate
```

---

## 🧪 Automated Tests

Run the comprehensive 8-suite automated test runner:
```bash
swift run CaffeinateTestRunner
```

Verified test suites:
1. `PowerManager` activation and mode switching (`display` vs `system`).
2. `PowerManager` toggle behavior.
3. `BatteryStatus` string formatting across all AC/battery states.
4. `BatteryMonitor` hardware power source detection.
5. `DurationOption` presets, second conversions, and formatting.
6. `TimerManager` countdown, tick callback, and auto-stop lifecycle.
7. System `pmset` powerd registry verification (confirms assertion registration and clean release).
8. `SharedStateManager` cross-process JSON encoding, disk persistence, and decoding.

---

## 🔍 System Verification via Terminal

You can verify that Caffeinate is actively holding system sleep assertions at any time using macOS's built-in `pmset`:
```bash
pmset -g assertions
```

When active, you will observe:
```text
PreventUserIdleDisplaySleep named: "Caffeinate Sleep Prevention"
```
When deactivated or expired, the assertion is immediately released from the kernel power daemon.
