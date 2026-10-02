# caffeinate-for-mac
A native, ultra-lightweight macOS menu bar &amp; desktop widget utility that prevents your Mac from sleeping. Built with Swift 6, SwiftUI, native IOKit power assertions, WidgetKit, and low-battery protection.


# Brief Project Description
Caffeinate is a modern, privacy-focused macOS system utility designed to keep your Mac awake on your exact terms. Unlike legacy utilities that spawn dangling background shell processes (/usr/bin/caffeinate), Caffeinate communicates directly with Apple's Darwin
kernel using in-process IOKit power assertions for instantaneous response and zero CPU overhead.

#### Key Highlights

  • 🎨 Modern Visual Identity: Custom glassmorphism squircle app icon (AppIcon.icns) with neon amber-cyan espresso steam and dynamic status bar SF Symbols.
  • 🚀 First-Launch Popup Dashboard: Floating translucent SwiftUI window (NSPanel) that greets users upon opening with large glowing toggle controls, mode selectors, and duration presets.
  • 🧩 Dual Widget Support:
      • Menu Bar Interactive Widget Popover: Quick Control Center-style card attached to the status bar icon.
      • macOS WidgetKit Extension (CaffeinateWidget.appex): Native desktop & Notification Center widget (.systemSmall and .systemMedium) in macOS's Widget Gallery / Widget list with one-tap toggle.
  • 🖥️ Dual Sleep Modes: Choose between Display & System Sleep (screen stays awake) and System Sleep Only (screen turns off while background tasks, renders, and downloads continue).
  • ⏱️ Duration Presets: Quick options for Indefinite, 15m, 30m, 1h, 2h, and 4h with live 1Hz countdown display.
  • 🔋 Automated Low Battery Protection: Continuously monitors hardware power sources via IOKit.ps and automatically releases wake locks if battery drops to ≤ 20% while discharging.
  • 🔒 100% Private: Zero analytics, zero tracking, and zero outbound network connections.


### Technologies Included
Layer / Domain                                    | Technology                                        | Purpose in Project
  ---------------------------------------------------|---------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------
   Language & Toolchain                              | Swift 6                                           | Modern, memory-safe language leveraging strict concurrency and @MainActor state dispatching.
   Build System                                      | Swift Package Manager (SPM)                       | Modular target architecture (CaffeinateKit, Caffeinate, CaffeinateTestRunner).
   Kernel Power Management                           | IOKit (IOKit.pwr_mgt)                             | Calls IOPMAssertionCreateWithName and IOPMAssertionRelease for kIOPMAssertionTypePreventUserIdleDisplaySleep and kIOPMAssertionTypePreventUserIdleSystemSleep.
   Hardware Telemetry                                | IOKit (IOKit.ps)                                  | Queries IOPSCopyPowerSourcesInfo for real-time AC vs. battery status, charging state, and remaining percentage.
   Presentation Framework                            | SwiftUI                                           | Powers the modern floating Dashboard UI (DashboardView), the Menu Bar Popover (PopoverWidgetView), and the WidgetKit views.
   System Windowing & Shell                          | AppKit                                            | Manages NSStatusItem in the system menu bar, floating NSPanel (.hudWindow vibrancy), and NSPopover.
   Desktop & Sidebar Widgets                         | WidgetKit (WidgetBundle)                          | Compiles into a standalone .appex extension bundle providing interactive Small and Medium widgets for macOS Sonoma & Sequoia.
   Cross-Process IPC                                 | JSON & DistributedNotificationCenter              | Syncs real-time state between the main app and the sandboxed WidgetKit extension (state.json + WidgetCenter.reloadAllTimelines()).
   Deep-Linking & Shortcuts                          | Custom URL Scheme (caffeinate://)                 | Supports programmatic actions (caffeinate://toggle, activate, dashboard) from widgets, terminal, or Raycast/Alfred.
   System Notifications                              | UserNotifications Framework                       | Dispatches native macOS notification banners when scheduled sessions end or battery cutoffs trigger.
   Packaging & Code Signing                          | Shell + codesign                                  | Automated bundling script (scripts/build_app.sh) generating a signed, distribution-ready Caffeinate.app bundle.
  ──────


  ### 🚀 Quick Start

    ```bash
    # Clone the repository
    git clone https://github.com/your-username/caffeinate.git
    cd caffeinate

    # Build the release .app bundle (includes Desktop Widget)
    ./scripts/build_app.sh

    # Launch Caffeinate (Dashboard will appear on launch)
    open build/Caffeinate.app
