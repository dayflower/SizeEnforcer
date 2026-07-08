import AppKit
import Combine

/// Menu-bar resident controller. Owns the status item, the preset store, and
/// starts the window picker on demand.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let picker = WindowPicker()
    private let store = PresetStore()
    private let shortcutStore = ShortcutStore()
    private let generalStore = GeneralSettingsStore()
    private var shortcutObserver: AnyCancellable?

    private lazy var settingsController = SettingsWindowController(
        store: store,
        shortcutStore: shortcutStore,
        generalStore: generalStore
    )
    private lazy var selectionMenu = SelectionMenuController(store: store) { [weak self] in
        self?.settingsController.show()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "rectangle.dashed",
                accessibilityDescription: "SizeEnforcer"
            )
        }

        let menu = NSMenu()
        let versionItem = NSMenuItem(title: appVersionTitle(), action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Resize window…",
            action: #selector(pickWindow),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit",
            action: #selector(quit),
            keyEquivalent: "q"
        ).target = self

        item.menu = menu
        statusItem = item

        // Registers on launch (sink fires with the current value) and again
        // whenever the user records a different shortcut in Settings.
        shortcutObserver = shortcutStore.$shortcut.sink { [weak self] shortcut in
            self?.applyShortcut(shortcut)
        }

        appLogger.notice("SizeEnforcer launched")
    }

    private func applyShortcut(_ shortcut: HotKeyShortcut?) {
        if let shortcut {
            HotKeyCenter.shared.register(shortcut) { [weak self] in
                self?.pickWindow()
            }
        } else {
            HotKeyCenter.shared.unregister()
        }
    }

    @objc private func pickWindow() {
        guard !picker.isActive else { return }
        let mode: HighlightMode = generalStore.excludeOccludedAreas ? .visibleAreaOnly : .fullWindow
        picker.begin(highlightMode: mode) { [weak self] selection in
            self?.handleSelection(selection)
        }
    }

    @objc private func openSettings() {
        settingsController.show()
    }

    private func handleSelection(_ selection: WindowInfo?) {
        guard let window = selection else { return }
        let identity = AppIdentity.resolve(pid: window.ownerPID, fallbackName: window.ownerName)
        // The cursor is at the click location; show the popup there.
        selectionMenu.show(for: window, identity: identity, at: NSEvent.mouseLocation)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    /// Menu title showing the app's marketing version, e.g. "SizeEnforcer 0.1.0".
    /// Falls back to just the name when run without a bundle (e.g. `swift run`).
    private func appVersionTitle() -> String {
        let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SizeEnforcer"
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return name
        }
        return "\(name) \(version)"
    }
}
