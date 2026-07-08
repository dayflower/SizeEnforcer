import CoreGraphics
import Foundation

/// Result of resolving the window under the cursor.
struct WindowHit {
    /// The target window (front-most normal window under the cursor).
    let window: WindowInfo
    /// Bounds of windows drawn in front of the target that overlap it, in
    /// flipped global display coordinates (top-left origin). Used to exclude
    /// occluded areas from the highlight.
    let occluders: [CGRect]
}

/// Enumerates on-screen windows and resolves which one sits under a point.
enum WindowEnumerator {
    /// An eligible on-screen window paired with its window-server layer.
    ///
    /// Layer information is retained so callers can distinguish normal windows
    /// (layer 0) from floating panels and system UI drawn in front of them.
    struct Entry {
        let info: WindowInfo
        let layer: Int
    }

    /// Parses a single `CGWindowListCopyWindowInfo` entry, applying the
    /// eligibility filters. Returns `nil` for windows that should be excluded:
    /// those owned by `selfPID` (our own overlay), effectively invisible ones
    /// (alpha ~ 0), zero-sized ones, and entries missing required keys.
    ///
    /// Pure function, so it is unit-testable with dictionary fixtures.
    static func entry(from raw: [String: Any], selfPID: pid_t) -> Entry? {
        guard
            let pid = raw[kCGWindowOwnerPID as String] as? pid_t,
            pid != selfPID
        else { return nil }

        if let alpha = raw[kCGWindowAlpha as String] as? Double, alpha <= 0.01 {
            return nil
        }

        guard
            let windowNumber = raw[kCGWindowNumber as String] as? CGWindowID,
            let boundsDict = raw[kCGWindowBounds as String] as? NSDictionary,
            let bounds = CGRect(dictionaryRepresentation: boundsDict)
        else { return nil }

        if bounds.width <= 0 || bounds.height <= 0 {
            return nil
        }

        let layer = raw[kCGWindowLayer as String] as? Int ?? 0
        let ownerName = raw[kCGWindowOwnerName as String] as? String ?? "(unknown)"

        return Entry(
            info: WindowInfo(
                windowNumber: windowNumber,
                ownerName: ownerName,
                ownerPID: pid,
                bounds: bounds
            ),
            layer: layer
        )
    }

    /// Returns eligible on-screen windows in front-to-back order.
    ///
    /// Desktop elements are excluded via the query option; the remaining
    /// per-window filtering is delegated to `entry(from:selfPID:)`.
    private static func entries() -> [Entry] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return []
        }

        let selfPID = getpid()
        return raw.compactMap { entry(from: $0, selfPID: selfPID) }
    }

    /// Resolves the front-most normal window under `point` from `entries`
    /// (front-to-back order), together with the windows in front of it that
    /// overlap it.
    ///
    /// `point` must be expressed in flipped global display coordinates
    /// (top-left origin), matching `CGEvent.location`. Pure function, so it is
    /// unit-testable.
    static func windowUnderCursor(in entries: [Entry], at point: CGPoint) -> WindowHit? {
        guard
            let index = entries.firstIndex(where: {
                $0.layer == 0 && $0.info.bounds.contains(point)
            })
        else {
            return nil
        }

        let target = entries[index].info
        let occluders = entries[0..<index]
            .map(\.info.bounds)
            .filter { $0.intersects(target.bounds) }

        return WindowHit(window: target, occluders: occluders)
    }

    /// Returns the front-most normal window under `point` together with the
    /// windows in front of it that overlap it.
    ///
    /// `point` must be expressed in flipped global display coordinates
    /// (top-left origin), matching `CGEvent.location`.
    static func windowUnderCursor(at point: CGPoint) -> WindowHit? {
        windowUnderCursor(in: entries(), at: point)
    }
}
