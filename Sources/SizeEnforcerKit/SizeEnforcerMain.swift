import AppKit

/// Application entry point.
///
/// Configures the shared `NSApplication` as a menu-bar resident app (no Dock
/// icon, no main window) and runs the event loop. This is the only public API
/// of `SizeEnforcerKit`; the `SizeEnforcer` executable target calls it from its
/// `main.swift`. Everything else stays `internal` and is exercised through
/// `@testable import`.
@MainActor
public func sizeEnforcerMain() -> Never {
    let app = NSApplication.shared

    // Menu-bar resident app: no Dock icon, no main window.
    app.setActivationPolicy(.accessory)

    let delegate = AppDelegate()
    app.delegate = delegate

    app.run()

    // `NSApplication.run()` only returns after `terminate(_:)`, which exits the
    // process; this keeps the signature `-> Never`.
    exit(EXIT_SUCCESS)
}
