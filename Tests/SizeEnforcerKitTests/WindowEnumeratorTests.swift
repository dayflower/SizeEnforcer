import CoreGraphics
import Foundation
import Testing

@testable import SizeEnforcerKit

@Suite
struct WindowEnumeratorTests {
    /// Builds a `CGWindowListCopyWindowInfo`-shaped dictionary. Keys can be
    /// omitted (pass `nil`) to exercise the missing-key paths.
    private func rawEntry(
        pid: pid_t? = 1000,
        windowNumber: CGWindowID? = 1,
        bounds: CGRect? = CGRect(x: 0, y: 0, width: 100, height: 100),
        alpha: Double? = nil,
        layer: Int? = nil,
        ownerName: String? = nil
    ) -> [String: Any] {
        var raw: [String: Any] = [:]
        if let pid { raw[kCGWindowOwnerPID as String] = pid }
        if let windowNumber { raw[kCGWindowNumber as String] = windowNumber }
        if let bounds { raw[kCGWindowBounds as String] = bounds.dictionaryRepresentation }
        if let alpha { raw[kCGWindowAlpha as String] = alpha }
        if let layer { raw[kCGWindowLayer as String] = layer }
        if let ownerName { raw[kCGWindowOwnerName as String] = ownerName }
        return raw
    }

    // MARK: - entry(from:selfPID:)

    @Test
    func parsesEligibleEntry() {
        let raw = rawEntry(
            pid: 42,
            windowNumber: 7,
            bounds: CGRect(x: 10, y: 20, width: 300, height: 200),
            layer: 0,
            ownerName: "Safari"
        )
        let entry = WindowEnumerator.entry(from: raw, selfPID: 999)
        #expect(entry != nil)
        #expect(entry?.info.windowNumber == 7)
        #expect(entry?.info.ownerPID == 42)
        #expect(entry?.info.ownerName == "Safari")
        #expect(entry?.info.bounds == CGRect(x: 10, y: 20, width: 300, height: 200))
        #expect(entry?.layer == 0)
    }

    @Test
    func excludesOwnProcess() {
        let raw = rawEntry(pid: 500)
        #expect(WindowEnumerator.entry(from: raw, selfPID: 500) == nil)
    }

    @Test
    func excludesEffectivelyInvisibleWindows() {
        let raw = rawEntry(alpha: 0.01)
        #expect(WindowEnumerator.entry(from: raw, selfPID: 999) == nil)
    }

    @Test
    func keepsPartiallyTransparentWindows() {
        let raw = rawEntry(alpha: 0.5)
        #expect(WindowEnumerator.entry(from: raw, selfPID: 999) != nil)
    }

    @Test
    func excludesZeroSizedWindows() {
        let raw = rawEntry(bounds: CGRect(x: 0, y: 0, width: 0, height: 100))
        #expect(WindowEnumerator.entry(from: raw, selfPID: 999) == nil)
    }

    @Test
    func skipsEntriesMissingRequiredKeys() {
        #expect(WindowEnumerator.entry(from: rawEntry(pid: nil), selfPID: 999) == nil)
        #expect(WindowEnumerator.entry(from: rawEntry(windowNumber: nil), selfPID: 999) == nil)
        #expect(WindowEnumerator.entry(from: rawEntry(bounds: nil), selfPID: 999) == nil)
    }

    @Test
    func usesDefaultsForLayerAndOwnerName() {
        // layer and ownerName omitted → default to 0 and "(unknown)".
        let entry = WindowEnumerator.entry(from: rawEntry(), selfPID: 999)
        #expect(entry?.layer == 0)
        #expect(entry?.info.ownerName == "(unknown)")
    }

    // MARK: - windowUnderCursor(in:at:)

    private func entry(
        pid: pid_t,
        bounds: CGRect,
        layer: Int
    ) -> WindowEnumerator.Entry {
        WindowEnumerator.Entry(
            info: WindowInfo(
                windowNumber: CGWindowID(pid),
                ownerName: "App\(pid)",
                ownerPID: pid,
                bounds: bounds
            ),
            layer: layer
        )
    }

    @Test
    func picksFrontMostNormalWindow() {
        // Front-to-back: two overlapping layer-0 windows under the point.
        let entries = [
            entry(pid: 1, bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 0),
            entry(pid: 2, bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 0),
        ]
        let hit = WindowEnumerator.windowUnderCursor(in: entries, at: CGPoint(x: 50, y: 50))
        #expect(hit?.window.ownerPID == 1)
    }

    @Test
    func ignoresNonNormalLayersAsTargetButTreatsThemAsOccluders() {
        // A floating panel (layer > 0) sits in front of and overlaps the target;
        // it is not a valid target but is collected as an occluder.
        let entries = [
            entry(pid: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100), layer: 25),
            entry(pid: 2, bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 0),
        ]
        let hit = WindowEnumerator.windowUnderCursor(in: entries, at: CGPoint(x: 50, y: 50))
        #expect(hit?.window.ownerPID == 2)
        #expect(hit?.occluders == [CGRect(x: 0, y: 0, width: 100, height: 100)])
    }

    @Test
    func collectsOnlyOverlappingOccluders() {
        // Two windows in front of the target: one overlaps, one does not.
        let entries = [
            entry(pid: 1, bounds: CGRect(x: 500, y: 500, width: 50, height: 50), layer: 0),
            entry(pid: 2, bounds: CGRect(x: 10, y: 10, width: 40, height: 40), layer: 0),
            entry(pid: 3, bounds: CGRect(x: 0, y: 0, width: 200, height: 200), layer: 0),
        ]
        let hit = WindowEnumerator.windowUnderCursor(in: entries, at: CGPoint(x: 100, y: 100))
        #expect(hit?.window.ownerPID == 3)
        #expect(hit?.occluders == [CGRect(x: 10, y: 10, width: 40, height: 40)])
    }

    @Test
    func returnsNilWhenNoWindowUnderCursor() {
        let entries = [
            entry(pid: 1, bounds: CGRect(x: 0, y: 0, width: 100, height: 100), layer: 0),
        ]
        let hit = WindowEnumerator.windowUnderCursor(in: entries, at: CGPoint(x: 500, y: 500))
        #expect(hit == nil)
    }
}
