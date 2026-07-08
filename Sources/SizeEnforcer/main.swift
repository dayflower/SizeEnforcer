import AppKit

let app = NSApplication.shared

// Menu-bar resident app: no Dock icon, no main window.
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.run()
