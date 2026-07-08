import AppKit
import ApplicationServices

/// Resizes windows of other applications via the Accessibility API.
enum WindowResizer {
    enum Result {
        case success
        case notPermitted
        case windowNotFound
        case failed
    }

    /// Whether this process is currently trusted for Accessibility.
    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant Accessibility permission (opens System
    /// Settings). Returns the current trust state.
    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        // Value of `kAXTrustedCheckOptionPrompt`; referenced by literal to avoid
        // the non-concurrency-safe global under Swift 6.
        let key = "AXTrustedCheckOptionPrompt" as CFString
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Resizes `window` to `size`, keeping its top-left position unchanged.
    static func resize(_ window: WindowInfo, to size: CGSize) -> Result {
        guard hasAccessibilityPermission else { return .notPermitted }

        let appElement = AXUIElementCreateApplication(window.ownerPID)
        guard let axWindow = matchingAXWindow(in: appElement, bounds: window.bounds) else {
            return .windowNotFound
        }

        return setSize(size, on: [axWindow])
    }

    /// Resizes every window of the app with `pid` to `size`, keeping each
    /// window's top-left position unchanged.
    static func resizeAllWindows(ofPID pid: pid_t, to size: CGSize) -> Result {
        guard hasAccessibilityPermission else { return .notPermitted }

        let appElement = AXUIElementCreateApplication(pid)
        let windows = axWindows(of: appElement)
        guard !windows.isEmpty else { return .windowNotFound }

        return setSize(size, on: windows)
    }

    // MARK: - Window matching

    /// Maximum positional distance (in points) allowed when matching an
    /// on-screen window to an AX window, to avoid resizing the wrong window.
    static let matchTolerance: CGFloat = 10

    /// Returns the index of the position closest to `target`, provided it lies
    /// within `tolerance`. `nil` entries are skipped. Returns `nil` when there
    /// are no candidates or the nearest one is farther than `tolerance`.
    ///
    /// Pure function, so it is unit-testable.
    static func bestMatchIndex(
        positions: [CGPoint?],
        target: CGPoint,
        tolerance: CGFloat
    ) -> Int? {
        var best: (index: Int, distance: CGFloat)?
        for (index, position) in positions.enumerated() {
            guard let position else { continue }
            let distance = hypot(position.x - target.x, position.y - target.y)
            if best == nil || distance < best!.distance {
                best = (index, distance)
            }
        }

        guard let match = best, match.distance <= tolerance else { return nil }
        return match.index
    }

    /// Sets the AX size on each element. Succeeds if at least one is resized.
    private static func setSize(_ size: CGSize, on elements: [AXUIElement]) -> Result {
        var newSize = size
        guard let value = AXValueCreate(.cgSize, &newSize) else { return .failed }

        var anySuccess = false
        for element in elements {
            if AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value) == .success {
                anySuccess = true
            }
        }
        return anySuccess ? .success : .failed
    }

    /// Returns all AX windows of an application element.
    private static func axWindows(of appElement: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &value
        )
        guard status == .success, let windows = value as? [AXUIElement] else {
            return []
        }
        return windows
    }

    /// Finds the AX window whose on-screen position best matches `bounds`.
    private static func matchingAXWindow(
        in appElement: AXUIElement,
        bounds: CGRect
    ) -> AXUIElement? {
        let windows = axWindows(of: appElement)
        let positions = windows.map { position(of: $0) }
        guard
            let index = bestMatchIndex(
                positions: positions,
                target: bounds.origin,
                tolerance: matchTolerance
            )
        else { return nil }
        return windows[index]
    }

    private static func position(of element: AXUIElement) -> CGPoint? {
        var value: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &value)
                == .success,
            let axValue = value,
            CFGetTypeID(axValue) == AXValueGetTypeID()
        else {
            return nil
        }

        var point = CGPoint.zero
        // swiftlint:disable:next force_cast
        AXValueGetValue(axValue as! AXValue, .cgPoint, &point)
        return point
    }
}
