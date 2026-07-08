import Foundation

/// Stores registered sizes per application and persists them to a JSON file in
/// Application Support. Shared between the selection popup (AppKit) and the
/// settings window (SwiftUI), hence `ObservableObject`.
@MainActor
final class PresetStore: ObservableObject {
    /// App presets keyed by bundle identifier.
    @Published private(set) var apps: [String: AppPresets] = [:]

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        load()
    }

    // MARK: - Queries

    /// Apps that have at least one preset, sorted by display name.
    var sortedApps: [AppPresets] {
        apps.values.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func presets(forBundleID bundleID: String) -> [SizePreset] {
        apps[bundleID]?.presets ?? []
    }

    // MARK: - Mutations

    /// Adds a preset for the app, creating the app entry if needed. The display
    /// name is refreshed to the most recently seen value.
    func addPreset(bundleID: String, displayName: String, width: Int, height: Int) {
        var entry = apps[bundleID] ?? AppPresets(bundleID: bundleID, displayName: displayName, presets: [])
        entry.displayName = displayName
        entry.presets.append(SizePreset(width: width, height: height))
        apps[bundleID] = entry
        save()
    }

    /// Removes a preset. Empties out the app entry entirely when its last preset
    /// is removed.
    func removePreset(bundleID: String, id: SizePreset.ID) {
        guard var entry = apps[bundleID] else { return }
        entry.presets.removeAll { $0.id == id }
        if entry.presets.isEmpty {
            apps[bundleID] = nil
        } else {
            apps[bundleID] = entry
        }
        save()
    }

    /// Removes an app entirely, along with all of its registered sizes.
    func removeApp(bundleID: String) {
        guard apps[bundleID] != nil else { return }
        apps[bundleID] = nil
        save()
    }

    /// Refreshes the stored display name for an app if it already exists.
    func updateDisplayName(bundleID: String, displayName: String) {
        guard var entry = apps[bundleID], entry.displayName != displayName else { return }
        entry.displayName = displayName
        apps[bundleID] = entry
        save()
    }

    // MARK: - Persistence

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base
            .appendingPathComponent("SizeEnforcer", isDirectory: true)
            .appendingPathComponent("presets.json", isDirectory: false)
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            let decoded = try JSONDecoder().decode([AppPresets].self, from: data)
            apps = Dictionary(uniqueKeysWithValues: decoded.map { ($0.bundleID, $0) })
        } catch {
            appLogger.error("Failed to load presets: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        let list = Array(apps.values)
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(list)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            appLogger.error("Failed to save presets: \(error.localizedDescription, privacy: .public)")
        }
    }
}
