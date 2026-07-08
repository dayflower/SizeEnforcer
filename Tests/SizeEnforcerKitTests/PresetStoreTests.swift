import Foundation
import Testing

@testable import SizeEnforcerKit

@MainActor
@Suite
struct PresetStoreTests {
    /// Creates a fresh, isolated file URL under a temporary directory.
    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("SizeEnforcerTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("presets.json", isDirectory: false)
    }

    // MARK: - Mutations

    @Test
    func addPresetCreatesNewApp() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)

        let presets = store.presets(forBundleID: "com.example.App")
        #expect(presets.count == 1)
        #expect(presets.first?.width == 1280)
        #expect(presets.first?.height == 800)
    }

    @Test
    func addPresetAppendsToExistingApp() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1920, height: 1080)

        #expect(store.presets(forBundleID: "com.example.App").count == 2)
    }

    @Test
    func addPresetRefreshesDisplayName() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Old Name", width: 1280, height: 800)
        store.addPreset(bundleID: "com.example.App", displayName: "New Name", width: 1920, height: 1080)

        #expect(store.apps["com.example.App"]?.displayName == "New Name")
    }

    @Test
    func removePresetDeletesAppWhenLastPresetRemoved() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)
        let id = store.presets(forBundleID: "com.example.App")[0].id

        store.removePreset(bundleID: "com.example.App", id: id)

        #expect(store.apps["com.example.App"] == nil)
    }

    @Test
    func removePresetKeepsAppWhenOtherPresetsRemain() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1920, height: 1080)
        let id = store.presets(forBundleID: "com.example.App")[0].id

        store.removePreset(bundleID: "com.example.App", id: id)

        #expect(store.presets(forBundleID: "com.example.App").count == 1)
    }

    @Test
    func removeAppDropsAllPresets() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)

        store.removeApp(bundleID: "com.example.App")

        #expect(store.apps["com.example.App"] == nil)
    }

    @Test
    func updateDisplayNameRefreshesExistingApp() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.App", displayName: "Old Name", width: 1280, height: 800)

        store.updateDisplayName(bundleID: "com.example.App", displayName: "New Name")

        #expect(store.apps["com.example.App"]?.displayName == "New Name")
    }

    @Test
    func updateDisplayNameIgnoresUnknownApp() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.updateDisplayName(bundleID: "com.example.Missing", displayName: "Name")

        #expect(store.apps["com.example.Missing"] == nil)
    }

    // MARK: - Queries

    @Test
    func sortedAppsIsCaseInsensitiveByDisplayName() {
        let store = PresetStore(fileURL: makeTempFileURL())
        store.addPreset(bundleID: "com.example.b", displayName: "banana", width: 100, height: 100)
        store.addPreset(bundleID: "com.example.a", displayName: "Apple", width: 100, height: 100)
        store.addPreset(bundleID: "com.example.c", displayName: "Cherry", width: 100, height: 100)

        #expect(store.sortedApps.map(\.displayName) == ["Apple", "banana", "Cherry"])
    }

    // MARK: - Persistence

    @Test
    func persistsAcrossInstances() {
        let fileURL = makeTempFileURL()
        let store = PresetStore(fileURL: fileURL)
        store.addPreset(bundleID: "com.example.App", displayName: "Example", width: 1280, height: 800)

        let reloaded = PresetStore(fileURL: fileURL)
        #expect(reloaded.presets(forBundleID: "com.example.App").count == 1)
        #expect(reloaded.apps["com.example.App"]?.displayName == "Example")
    }

    @Test
    func startsEmptyForMissingFile() {
        let store = PresetStore(fileURL: makeTempFileURL())
        #expect(store.apps.isEmpty)
    }

    @Test
    func startsEmptyForCorruptedJSON() throws {
        let fileURL = makeTempFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not valid json".utf8).write(to: fileURL)

        let store = PresetStore(fileURL: fileURL)
        #expect(store.apps.isEmpty)
    }

    /// Regression test for R2: duplicate bundle IDs must not crash on load.
    @Test
    func loadsDuplicateBundleIDsWithoutCrashing() throws {
        let fileURL = makeTempFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let json = """
        [
          { "bundleID": "com.example.App", "displayName": "First", "presets": [] },
          { "bundleID": "com.example.App", "displayName": "Second", "presets": [] }
        ]
        """
        try Data(json.utf8).write(to: fileURL)

        let store = PresetStore(fileURL: fileURL)
        #expect(store.apps.count == 1)
        // The last occurrence wins.
        #expect(store.apps["com.example.App"]?.displayName == "Second")
    }
}
