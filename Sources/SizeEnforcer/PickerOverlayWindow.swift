import AppKit

/// Borderless, transparent window spanning every screen. Hosts the picker
/// overlay view and captures mouse / keyboard input during selection.
final class PickerOverlayWindow: NSWindow {
    let overlayView: PickerOverlayView

    init() {
        let frame = ScreenGeometry.totalFrame
        let view = PickerOverlayView(frame: CGRect(origin: .zero, size: frame.size))
        self.overlayView = view

        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
