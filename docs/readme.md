# ☕ Caffeinate: Project Knowledge Base & Overview

Welcome to the **Caffeinate** documentation repository. This document serves as the entry point to the complete technical, operational, product, and business documentation for the Caffeinate macOS utility.

---

## 📚 Documentation Index

| Document | Purpose | Target Audience |
| :--- | :--- | :--- |
| 📖 **[Developer Guide](file:///Users/jatinsaini/Downloads/mac-workspace/projects/caffeinate/docs/developer.readme.md)** | Deep architectural walkthrough, IOKit APIs, WidgetKit extension, compilation pipelines, testing, and IPC. | Core Engineers, Contributors, System Architects |
| 📋 **[Product Requirements Document (PRD)](file:///Users/jatinsaini/Downloads/mac-workspace/projects/caffeinate/docs/prd.md)** | Functional specifications, user journeys, UI/UX designs, acceptance criteria, and edge-case handling. | Product Managers, Designers, QA Engineers |
| 💼 **[Business Requirements Document (BRD)](file:///Users/jatinsaini/Downloads/mac-workspace/projects/caffeinate/docs/brd.md)** | Strategic market positioning, competitive benchmarking against Amphetamine/Caffeine, monetization, and compliance. | Executives, Product Strategists, Investors |

---

## 🌟 Executive Overview

`Caffeinate` is a modern, native macOS menu bar and desktop widget application that prevents your Mac from sleeping. Built natively in **Swift 6** using **AppKit**, **SwiftUI**, Apple's **IOKit** power management subsystems, and **WidgetKit**, it operates with zero external subprocess overhead, instantaneous kernel assertion response, and complete battery safety awareness.

### Core Capabilities
1. **🎨 Visual Identity & App Icon**:
   - Modern glassmorphism squircle app icon (`AppIcon.icns`) with amber-cyan neon glowing coffee steam.
   - Dynamic template SF Symbols (`cup.and.saucer` / `cup.and.saucer.fill`) in the macOS status bar.
2. **🚀 First-Launch Popup UI (Interactive Dashboard)**:
   - Floating translucent SwiftUI window (`NSPanel`) that appears on first launch.
   - Large glowing one-tap toggle button with warm amber aura.
   - Sleep Mode Picker: **Display & System Sleep** vs. **System Sleep Only**.
   - Preset duration chips: **Indefinite**, **15m**, **30m**, **1h**, **2h**, **4h**.
   - Live battery gauge with **Auto-disable below 20% battery** protection toggle.
3. **🧩 Dual Widget Support**:
   - **Menu Bar Interactive Widget Popover**: Attached directly to the status icon for quick Control Center-style adjustments.
   - **macOS WidgetKit Extension (`CaffeinateWidget.appex`)**: Native desktop & Notification Center widget (`.systemSmall` and `.systemMedium`) in macOS's **Widget Gallery / Widget list**, with live state synchronization and one-tap toggle (`caffeinate://toggle`).
4. **⚡ Native In-Process IOKit Power Assertions**:
   - Directly calls `IOPMAssertionCreateWithName` and `IOPMAssertionRelease`.
   - Never spawns child shell processes (`/usr/bin/caffeinate`), eliminating zombie process risks and guaranteeing instantaneous release on quit.
5. **🔋 Low Battery Protection**:
   - Automatically monitors hardware power state via `IOKit.ps`.
   - Disables sleep prevention automatically when battery drops $\le 20\%$ while discharging to prevent unexpected shutdowns.
6. **🔔 Native System Notifications**:
   - Dispatches modern `UserNotifications` upon scheduled session completion or low-battery cutoff events.

---

## 🚀 Quick Execution Guide

### Build & Package Standalone Bundle (`Caffeinate.app`)
```bash
cd projects/caffeinate
./scripts/build_app.sh
```

### Launch Application
```bash
open build/Caffeinate.app
```
*The interactive Dashboard Popup UI will automatically appear in the center of the screen on launch.*

### Install to Applications (Enables Desktop & Notification Center Widgets)
```bash
cp -R build/Caffeinate.app /Applications/
```

### Run Automated Tests (8/8 Suites Passing)
```bash
swift run CaffeinateTestRunner
```

---

## 🏛️ Directory Layout

```
projects/caffeinate/
├── Package.swift                    # Swift Package Manager manifest
├── docs/                            # Project Knowledge Base
│   ├── readme.md                    # Main documentation index (this file)
│   ├── read.md                      # Knowledge summary alias
│   ├── developer.readme.md          # Technical developer & architecture manual
│   ├── prd.md                       # Product Requirements Document
│   └── brd.md                       # Business Requirements Document
├── Resources/
│   ├── AppIcon.icns                 # High-resolution macOS multi-layer icon
│   └── app_logo.png                 # High-resolution PNG logo
├── Sources/
│   ├── Caffeinate/                  # Executable entry point
│   ├── CaffeinateKit/               # Core framework library
│   ├── CaffeinateWidget/            # macOS WidgetKit extension
│   └── CaffeinateTestRunner/        # Standalone test runner (8 suites)
└── scripts/
    └── build_app.sh                 # Release compilation & bundle packager
```
