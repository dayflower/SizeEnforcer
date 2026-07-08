import AppKit

/// Drives the interactive window-selection mode: it shows the overlay, tracks
/// the window under the cursor, and reports the confirmed selection.
@MainActor
final class WindowPicker: NSObject, PickerOverlayViewDelegate {
    private var overlay: PickerOverlayWindow?
    private var hoveredWindow: WindowInfo?
    private var completion: ((WindowInfo?) -> Void)?

    /// Whether a selection session is currently active.
    var isActive: Bool { overlay != nil }

    /// Begins a selection session. `completion` is invoked with the selected
    /// window, or `nil` if the user cancelled.
    func begin(highlightMode: HighlightMode, completion: @escaping (WindowInfo?) -> Void) {
        guard overlay == nil else { return }
        self.completion = completion

        let window = PickerOverlayWindow()
        window.overlayView.delegate = self
        window.overlayView.highlightMode = highlightMode
        overlay = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Prime the highlight with the window currently under the cursor.
        if let location = CGEvent(source: nil)?.location {
            overlayView(window.overlayView, didHoverAt: location)
        }
    }

    private func finish(with selection: WindowInfo?) {
        let completion = self.completion
        self.completion = nil
        hoveredWindow = nil

        overlay?.orderOut(nil)
        overlay = nil

        completion?(selection)
    }

    // MARK: - PickerOverlayViewDelegate

    func overlayView(_ view: PickerOverlayView, didHoverAt flippedPoint: CGPoint) {
        let hit = WindowEnumerator.windowUnderCursor(at: flippedPoint)
        hoveredWindow = hit?.window
        view.setHighlight(bounds: hit?.window.bounds, occluders: hit?.occluders ?? [])
    }

    func overlayViewDidConfirm(_ view: PickerOverlayView) {
        finish(with: hoveredWindow)
    }

    func overlayViewDidCancel(_ view: PickerOverlayView) {
        finish(with: nil)
    }
}
