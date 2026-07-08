import Carbon.HIToolbox
import Foundation
import Testing

@testable import SizeEnforcerKit

@MainActor
@Suite
struct ShortcutStoreTests {
    /// A fresh, isolated `UserDefaults` suite that is cleared after the test.
    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "SizeEnforcerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }

    @Test
    func persistsAcrossInstances() {
        withDefaults { defaults in
            let store = ShortcutStore(defaults: defaults)
            store.shortcut = HotKeyShortcut(
                keyCode: UInt32(kVK_ANSI_R), carbonModifiers: UInt32(cmdKey | optionKey))

            let reloaded = ShortcutStore(defaults: defaults)
            #expect(reloaded.shortcut == store.shortcut)
        }
    }

    @Test
    func settingNilRemovesStoredValue() {
        withDefaults { defaults in
            let store = ShortcutStore(defaults: defaults)
            store.shortcut = HotKeyShortcut(
                keyCode: UInt32(kVK_ANSI_R), carbonModifiers: UInt32(cmdKey))
            store.shortcut = nil

            #expect(defaults.data(forKey: "pickWindowShortcut") == nil)
            let reloaded = ShortcutStore(defaults: defaults)
            #expect(reloaded.shortcut == nil)
        }
    }

    @Test
    func startsNilWhenUnset() {
        withDefaults { defaults in
            let store = ShortcutStore(defaults: defaults)
            #expect(store.shortcut == nil)
        }
    }
}
