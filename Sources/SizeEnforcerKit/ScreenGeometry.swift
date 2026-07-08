import AppKit
import CoreGraphics

/// Helpers for converting between the flipped global display coordinate space
/// used by CoreGraphics (top-left origin) and AppKit's global coordinate space
/// (bottom-left origin).
enum ScreenGeometry {
    /// Height of the primary display (the screen whose origin is at (0, 0)).
    ///
    /// The flip between the two coordinate spaces is defined relative to this
    /// height.
    static var primaryDisplayHeight: CGFloat {
        if let primary = NSScreen.screens.first(where: { $0.frame.origin == .zero }) {
            return primary.frame.height
        }
        return NSScreen.main?.frame.height ?? 0
    }

    /// The union of all screen frames, in AppKit global coordinates.
    static var totalFrame: CGRect {
        NSScreen.screens.reduce(CGRect.null) { $0.union($1.frame) }
    }

    /// Converts a rect from flipped global display coordinates (top-left origin)
    /// to AppKit global coordinates (bottom-left origin), relative to the primary
    /// display height. Pure function, so it is unit-testable.
    static func appKitRect(fromFlipped rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts a rect from flipped global display coordinates (top-left origin)
    /// to AppKit global coordinates (bottom-left origin), using the current
    /// primary display height.
    static func appKitRect(fromFlipped rect: CGRect) -> CGRect {
        appKitRect(fromFlipped: rect, primaryHeight: primaryDisplayHeight)
    }
}
