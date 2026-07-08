import AppKit
import Carbon.HIToolbox
import SwiftUI

/// A SwiftUI control that records a keyboard shortcut. Click to start, then
/// press the desired combination; Escape cancels, Delete clears.
struct ShortcutRecorder: NSViewRepresentable {
    @Binding var shortcut: HotKeyShortcut?

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.shortcut = shortcut
        button.onCapture = { shortcut = $0 }
        return button
    }

    func updateNSView(_ nsView: RecorderButton, context: Context) {
        nsView.onCapture = { shortcut = $0 }
        if nsView.shortcut != shortcut {
            nsView.shortcut = shortcut
        }
    }
}

/// Push button that, while recording, captures the next key-down as a shortcut.
final class RecorderButton: NSButton {
    var onCapture: ((HotKeyShortcut?) -> Void)?

    var shortcut: HotKeyShortcut? {
        didSet { updateTitle() }
    }

    private var isRecording = false {
        didSet { updateTitle() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        bezelStyle = .rounded
        setButtonType(.momentaryPushIn)
        target = self
        action = #selector(toggleRecording)
        updateTitle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var acceptsFirstResponder: Bool { true }

    @objc private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            isRecording = true
            window?.makeFirstResponder(self)
        }
    }

    private func stopRecording() {
        isRecording = false
        if window?.firstResponder === self {
            window?.makeFirstResponder(nil)
        }
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        switch Int(event.keyCode) {
        case kVK_Escape:
            stopRecording()
        case kVK_Delete, kVK_ForwardDelete:
            shortcut = nil
            onCapture?(nil)
            stopRecording()
        default:
            if let captured = HotKeyShortcut(event: event) {
                shortcut = captured
                onCapture?(captured)
                stopRecording()
            }
            // Otherwise a bare key with no modifier — ignore and keep recording.
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // While recording, intercept combos that would otherwise be handled as
        // menu key equivalents (e.g. ⌘Q) so they can be captured instead.
        guard isRecording else {
            return super.performKeyEquivalent(with: event)
        }
        keyDown(with: event)
        return true
    }

    private func updateTitle() {
        if isRecording {
            title = "Type shortcut…"
        } else if let shortcut {
            title = shortcut.displayString
        } else {
            title = "Record Shortcut"
        }
    }
}
