import Foundation

/// Persists the user's Pick-window hotkey in `UserDefaults`. Observable so the
/// settings UI (SwiftUI) can bind to it and the app delegate can re-register the
/// Carbon hotkey whenever it changes.
@MainActor
final class ShortcutStore: ObservableObject {
    /// The current shortcut, or `nil` when none is set. Persisted on change.
    @Published var shortcut: HotKeyShortcut? {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let key = "pickWindowShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(HotKeyShortcut.self, from: data)
        {
            _shortcut = Published(initialValue: decoded)
        } else {
            _shortcut = Published(initialValue: nil)
        }
    }

    private func save() {
        if let shortcut, let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
