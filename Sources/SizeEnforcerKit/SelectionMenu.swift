import AppKit

/// Builds and shows the popup menu that appears after a window is picked. It
/// lists the app's registered sizes (apply on click), plus entries to register
/// the current size and open settings.
@MainActor
final class SelectionMenuController: NSObject, NSMenuDelegate {
    private let store: PresetStore
    private let resizer: WindowResizing
    private let presentAlert: @MainActor (_ title: String, _ message: String) -> Void
    private let onOpenSettings: () -> Void

    // Context for the currently shown menu.
    private var window: WindowInfo?
    private var identity: AppIdentity?

    init(
        store: PresetStore,
        resizer: WindowResizing = SystemWindowResizer(),
        presentAlert: @escaping @MainActor (_ title: String, _ message: String) -> Void
            = SelectionMenuController.runModalAlert,
        onOpenSettings: @escaping () -> Void
    ) {
        self.store = store
        self.resizer = resizer
        self.presentAlert = presentAlert
        self.onOpenSettings = onOpenSettings
    }

    /// Shows the menu at `screenPoint` (AppKit screen coordinates).
    func show(for window: WindowInfo, identity: AppIdentity, at screenPoint: NSPoint) {
        self.window = window
        self.identity = identity

        // Keep the stored display name fresh for apps that already exist.
        store.updateDisplayName(bundleID: identity.bundleID, displayName: identity.displayName)

        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self

        let header = NSMenuItem(title: identity.displayName, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let presets = store.presets(forBundleID: identity.bundleID)
        if presets.isEmpty {
            let empty = NSMenuItem(title: "No sizes registered", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for preset in presets {
                let item = NSMenuItem(
                    title: preset.label,
                    action: #selector(applyPreset(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = preset
                item.keyEquivalentModifierMask = []
                menu.addItem(item)

                // Alternate item shown only while Shift is held: applies the
                // size to every window of the app.
                let allItem = NSMenuItem(
                    title: "\(preset.label) — to All Windows",
                    action: #selector(applyPreset(_:)),
                    keyEquivalent: ""
                )
                allItem.target = self
                allItem.representedObject = preset
                allItem.keyEquivalentModifierMask = .shift
                allItem.isAlternate = true
                menu.addItem(allItem)
            }
        }

        menu.addItem(.separator())

        let width = Int(window.bounds.width.rounded())
        let height = Int(window.bounds.height.rounded())
        let registerItem = NSMenuItem(
            title: "Register current size (\(width) × \(height))",
            action: #selector(registerCurrentSize),
            keyEquivalent: ""
        )
        registerItem.target = self
        menu.addItem(registerItem)

        let settingsItem = NSMenuItem(
            title: "Open Settings…",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        if !resizer.hasAccessibilityPermission {
            menu.addItem(.separator())
            let note = NSMenuItem(
                title: "⚠ Accessibility permission required to resize",
                action: nil,
                keyEquivalent: ""
            )
            note.isEnabled = false
            menu.addItem(note)
        }

        menu.popUp(positioning: nil, at: screenPoint, in: nil)
    }

    // MARK: - Actions

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let window, let preset = sender.representedObject as? SizePreset else { return }
        // Holding Shift applies the size to every window of the same app.
        let allWindows = NSEvent.modifierFlags.contains(.shift)
        performResize(preset, on: window, allWindows: allWindows)
    }

    /// Applies `preset` to `window` (or all of the app's windows) and reports
    /// any failure through the injected resizer/alert. Pulled out of the menu
    /// action so the result branches can be exercised in tests.
    func performResize(_ preset: SizePreset, on window: WindowInfo, allWindows: Bool) {
        let size = CGSize(width: preset.width, height: preset.height)
        let result = allWindows
            ? resizer.resizeAllWindows(ofPID: window.ownerPID, to: size)
            : resizer.resize(window, to: size)

        switch result {
        case .success:
            break
        case .notPermitted:
            resizer.requestAccessibilityPermission()
            presentAlert(
                "Accessibility permission required",
                "Enable SizeEnforcer in System Settings > Privacy & Security > Accessibility."
            )
        case .windowNotFound:
            presentAlert("Could not resize", "The target window could not be located.")
        case .failed:
            presentAlert("Could not resize", "Failed to change the window size.")
        }
    }

    @objc private func registerCurrentSize() {
        guard let window, let identity else { return }
        store.addPreset(
            bundleID: identity.bundleID,
            displayName: identity.displayName,
            width: Int(window.bounds.width.rounded()),
            height: Int(window.bounds.height.rounded())
        )
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    // MARK: - Helpers

    /// Default alert presenter: shows a modal `NSAlert`.
    static func runModalAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.runModal()
    }
}
