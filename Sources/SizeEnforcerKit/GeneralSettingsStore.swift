import Foundation

/// General app preferences persisted in `UserDefaults`. Observable so the
/// settings UI (SwiftUI) can bind to it and the app delegate can read the
/// current value when starting the picker.
@MainActor
final class GeneralSettingsStore: ObservableObject {
    /// Whether occluded areas are excluded from the selection highlight.
    @Published var excludeOccludedAreas: Bool {
        didSet { defaults.set(excludeOccludedAreas, forKey: Self.excludeOccludedKey) }
    }

    private let defaults: UserDefaults
    private static let excludeOccludedKey = "excludeOccludedAreas"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Default to true when the user has never set the preference.
        if defaults.object(forKey: Self.excludeOccludedKey) == nil {
            _excludeOccludedAreas = Published(initialValue: true)
        } else {
            _excludeOccludedAreas = Published(
                initialValue: defaults.bool(forKey: Self.excludeOccludedKey))
        }
    }
}
