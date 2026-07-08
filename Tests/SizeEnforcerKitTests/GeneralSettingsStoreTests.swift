import Foundation
import Testing

@testable import SizeEnforcerKit

@MainActor
@Suite
struct GeneralSettingsStoreTests {
    /// A fresh, isolated `UserDefaults` suite that is cleared after the test.
    private func withDefaults(_ body: (UserDefaults) -> Void) {
        let suiteName = "SizeEnforcerTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        body(defaults)
    }

    @Test
    func defaultsToTrueWhenUnset() {
        withDefaults { defaults in
            let store = GeneralSettingsStore(defaults: defaults)
            #expect(store.excludeOccludedAreas == true)
        }
    }

    @Test
    func persistsExplicitFalse() {
        withDefaults { defaults in
            let store = GeneralSettingsStore(defaults: defaults)
            store.excludeOccludedAreas = false

            let reloaded = GeneralSettingsStore(defaults: defaults)
            #expect(reloaded.excludeOccludedAreas == false)
        }
    }

    @Test
    func persistsExplicitTrue() {
        withDefaults { defaults in
            let store = GeneralSettingsStore(defaults: defaults)
            store.excludeOccludedAreas = false
            store.excludeOccludedAreas = true

            let reloaded = GeneralSettingsStore(defaults: defaults)
            #expect(reloaded.excludeOccludedAreas == true)
        }
    }
}
