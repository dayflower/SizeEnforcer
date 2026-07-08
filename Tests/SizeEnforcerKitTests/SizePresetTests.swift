import Foundation
import Testing

@testable import SizeEnforcerKit

@Suite
struct SizePresetTests {
    @Test
    func labelFormat() {
        let preset = SizePreset(width: 1280, height: 800)
        #expect(preset.label == "1280 × 800")
    }

    @Test
    func sizePresetCodableRoundtrip() throws {
        let preset = SizePreset(width: 1920, height: 1080)
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(SizePreset.self, from: data)
        #expect(decoded == preset)
        #expect(decoded.id == preset.id)
    }

    @Test
    func appPresetsCodableRoundtrip() throws {
        let appPresets = AppPresets(
            bundleID: "com.example.App",
            displayName: "Example App",
            presets: [
                SizePreset(width: 1280, height: 800),
                SizePreset(width: 1920, height: 1080),
            ]
        )
        let data = try JSONEncoder().encode(appPresets)
        let decoded = try JSONDecoder().decode(AppPresets.self, from: data)
        #expect(decoded == appPresets)
    }
}
