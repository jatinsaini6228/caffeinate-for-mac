import AppKit
import CaffeinateKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// Install signal handlers so terminating from terminal cleanly releases any sleep assertions
signal(SIGINT) { _ in
    PowerManager.shared.deactivate()
    exit(0)
}
signal(SIGTERM) { _ in
    PowerManager.shared.deactivate()
    exit(0)
}

app.run()
