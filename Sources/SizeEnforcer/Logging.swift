import os

/// Shared logger for the application.
///
/// Log messages are also mirrored to stdout so that they are immediately
/// visible when the app is launched via `swift run`.
let appLogger = Logger(subsystem: "com.example.dayflower.SizeEnforcer", category: "picker")
