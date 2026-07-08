import AppKit

/// Receives user interaction from the picker overlay view.
@MainActor
protocol PickerOverlayViewDelegate: AnyObject {
    /// The cursor moved; resolve the window under `flippedPoint` (top-left origin).
    func overlayView(_ view: PickerOverlayView, didHoverAt flippedPoint: CGPoint)
    /// The user clicked to confirm the current selection.
    func overlayViewDidConfirm(_ view: PickerOverlayView)
    /// The user pressed Escape to cancel.
    func overlayViewDidCancel(_ view: PickerOverlayView)
}

/// Transparent view covering all screens. It draws a highlight over the window
/// currently under the cursor and forwards mouse / keyboard interaction.
final class PickerOverlayView: NSView {
    weak var delegate: PickerOverlayViewDelegate?

    /// Bounds of the highlighted window in flipped global display coordinates.
    private var highlightedFlippedBounds: CGRect?
    /// Bounds of windows in front of the highlighted window that overlap it,
    /// in flipped global display coordinates. Excluded from the highlight.
    private var occluderFlippedRects: [CGRect] = []

    /// Whether occluded areas are excluded from the highlight.
    var highlightMode: HighlightMode = .visibleAreaOnly {
        didSet {
            if highlightMode != oldValue { needsDisplay = true }
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    /// Updates the currently highlighted window and its occluders (bounds in
    /// flipped coordinates).
    func setHighlight(bounds: CGRect?, occluders: [CGRect]) {
        guard highlightedFlippedBounds != bounds || occluderFlippedRects != occluders
        else { return }
        highlightedFlippedBounds = bounds
        occluderFlippedRects = occluders
        needsDisplay = true
    }

    // MARK: - Tracking

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    // MARK: - Events

    override func mouseMoved(with event: NSEvent) {
        forwardHover()
    }

    override func mouseEntered(with event: NSEvent) {
        forwardHover()
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.overlayViewDidConfirm(self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {  // Escape
            delegate?.overlayViewDidCancel(self)
        } else {
            super.keyDown(with: event)
        }
    }

    private func forwardHover() {
        // CGEvent location is already in flipped global coordinates (top-left).
        guard let location = CGEvent(source: nil)?.location else { return }
        delegate?.overlayView(self, didHoverAt: location)
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()

        guard let flipped = highlightedFlippedBounds, let window else { return }

        // In visible-area-only mode, exclude the parts covered by windows drawn
        // in front of the target; otherwise highlight the whole window bounds.
        let visibleRects: [CGRect]
        switch highlightMode {
        case .visibleAreaOnly:
            visibleRects = RegionMath.visibleRegion(
                of: flipped,
                occludedBy: occluderFlippedRects
            )
        case .fullWindow:
            visibleRects = [flipped]
        }

        let path = NSBezierPath()
        for rect in visibleRects {
            // Convert flipped global bounds -> AppKit global -> view coordinates.
            let appKitRect = ScreenGeometry.appKitRect(fromFlipped: rect)
            let viewRect = appKitRect.offsetBy(
                dx: -window.frame.origin.x,
                dy: -window.frame.origin.y
            )
            path.appendRect(viewRect)
        }

        // A blue tint blended toward white, similar to the macOS screenshot
        // selection highlight.
        let tint = NSColor.systemBlue.blended(withFraction: 0.4, of: .white)
            ?? NSColor.systemBlue
        tint.withAlphaComponent(0.35).setFill()
        path.fill()
    }
}
