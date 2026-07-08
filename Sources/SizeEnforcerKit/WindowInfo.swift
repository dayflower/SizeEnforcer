import CoreGraphics
import Foundation

/// A snapshot of an on-screen window discovered via the CoreGraphics window list.
///
/// `bounds` is expressed in the global "flipped" display coordinate space that
/// `CGWindowListCopyWindowInfo` uses: the origin is the top-left of the primary
/// display and the y-axis grows downwards.
struct WindowInfo {
    let windowNumber: CGWindowID
    let ownerName: String
    let ownerPID: pid_t
    /// Window bounds in flipped global display coordinates (top-left origin).
    let bounds: CGRect
}
