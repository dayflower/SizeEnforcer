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
        var best: (element: AXUIElement, distance: CGFloat)?
        for element in axWindows(of: appElement) {
            guard let position = position(of: element) else { continue }
            let distance = hypot(position.x - bounds.origin.x, position.y - bounds.origin.y)
            if best == nil || distance < best!.distance {
                best = (element, distance)
            }
        }

        // Require a close positional match to avoid resizing the wrong window.
        guard let match = best, match.distance <= 10 else { return nil }
        return match.element
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
