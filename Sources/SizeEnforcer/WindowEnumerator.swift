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
    private struct Entry {
        let info: WindowInfo
        let layer: Int
    }

    /// Returns eligible on-screen windows in front-to-back order.
    ///
    /// Windows owned by this process (our overlay), effectively invisible
    /// windows (alpha ~ 0), and zero-sized windows are excluded. Desktop
    /// elements are excluded via the query option. Layer information is
    /// retained so callers can distinguish normal windows (layer 0) from
    /// floating panels and system UI drawn in front of them.
    private static func entries() -> [Entry] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else {
            return []
        }

        let selfPID = getpid()
        var result: [Entry] = []

        for entry in raw {
            guard
                let pid = entry[kCGWindowOwnerPID as String] as? pid_t,
                pid != selfPID
            else { continue }

            if let alpha = entry[kCGWindowAlpha as String] as? Double, alpha <= 0.01 {
                continue
            }

            guard
                let windowNumber = entry[kCGWindowNumber as String] as? CGWindowID,
                let boundsDict = entry[kCGWindowBounds as String] as? NSDictionary,
                let bounds = CGRect(dictionaryRepresentation: boundsDict)
            else { continue }

            if bounds.width <= 0 || bounds.height <= 0 {
                continue
            }

            let layer = entry[kCGWindowLayer as String] as? Int ?? 0
            let ownerName = entry[kCGWindowOwnerName as String] as? String ?? "(unknown)"

            result.append(
                Entry(
                    info: WindowInfo(
                        windowNumber: windowNumber,
                        ownerName: ownerName,
                        ownerPID: pid,
                        bounds: bounds
                    ),
                    layer: layer
                )
            )
        }

        return result
    }

    /// Returns the front-most normal window under `point` together with the
    /// windows in front of it that overlap it.
    ///
    /// `point` must be expressed in flipped global display coordinates
    /// (top-left origin), matching `CGEvent.location`.
    static func windowUnderCursor(at point: CGPoint) -> WindowHit? {
        let entries = entries()
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
}
