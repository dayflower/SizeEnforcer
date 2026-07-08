import AppKit

/// Stable identity used to group registered sizes per application.
struct AppIdentity {
    /// Grouping key: the app's bundle identifier when available, otherwise the
    /// window owner name as a fallback.
    let bundleID: String
    /// Human-readable name for display.
    let displayName: String
}

extension AppIdentity {
    /// Resolves the identity of the app that owns `pid`.
    ///
    /// Prefers the bundle identifier (stable across renames / updates). When it
    /// is unavailable (e.g. some system processes), falls back to the window
    /// owner name so presets can still be grouped.
    static func resolve(pid: pid_t, fallbackName: String) -> AppIdentity {
        let app = NSRunningApplication(processIdentifier: pid)
        let bundleID = app?.bundleIdentifier ?? fallbackName
        let displayName = app?.localizedName ?? fallbackName
        return AppIdentity(bundleID: bundleID, displayName: displayName)
    }
}
