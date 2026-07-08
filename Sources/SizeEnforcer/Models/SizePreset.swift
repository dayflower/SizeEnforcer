import Foundation

/// A registered target size for a window.
struct SizePreset: Codable, Identifiable, Equatable {
    let id: UUID
    var width: Int
    var height: Int

    init(id: UUID = UUID(), width: Int, height: Int) {
        self.id = id
        self.width = width
        self.height = height
    }

    /// Human-readable label such as "1280 × 800".
    var label: String { "\(width) × \(height)" }
}

/// The set of registered sizes for a single application, keyed by bundle
/// identifier. `displayName` is kept for presentation and refreshed whenever a
/// window of the app is picked.
struct AppPresets: Codable, Equatable {
    let bundleID: String
    var displayName: String
    var presets: [SizePreset]
}
